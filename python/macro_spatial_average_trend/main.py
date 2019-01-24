#!/usr/bin/env python3

from osgeo import gdal, osr
import os, sys
import subprocess
import numpy as np
from matplotlib import pyplot as plt
from copy import copy
import csv
MINTCAST_PATH = os.environ.get('MINTCAST_PATH')
dist_path = MINTCAST_PATH + '/dist/'
temp_path = MINTCAST_PATH + '/tmp/'
config_path = MINTCAST_PATH + "/config/"
sys.path.append(config_path)
from postgres_config import MONGODB_CONNECTION
import pymongo

# Calculate spatial average trend and export as csv

class raster:
	def __init__(self, filepath, var=""):
		self.filepath = filepath
		self.filename = os.path.basename(filepath)
		self.dir = os.path.dirname(filepath)
		self.ext = filepath.split('.')[-1]
		if self.ext in ["tif", "tiff"]: 
			raster = gdal.Open(filepath)
		elif self.ext == "nc":
			if var:
				raster = gdal.Open('NETCDF:"' + filepath + '":' + var)
			else: 
				print("Need to specify variable.")
		else:
			print("Unknown raster type, check type and code.")
		self.raster = raster
		self.xsize = raster.RasterXSize
		self.ysize = raster.RasterYSize
		self.matrix = raster.ReadAsArray(xoff=0, yoff=0, xsize=self.xsize, ysize=self.ysize)
		# Get Geographic meta data
		self.geo_trans = raster.GetGeoTransform()
		self.proj_str = raster.GetProjection()
		self.num_bands = raster.RasterCount
		self.cell_area = abs(self.geo_trans[1] * self.geo_trans[5])
		self.ulx, self.xres, self.xskew, self.uly, self.yskew, self.yres = raster.GetGeoTransform()
		self.lrx = self.ulx + self.xsize * self.xres 
		self.lry = self.uly + self.ysize * self.yres
		
	def plot(self):
		plt.imshow(self.matrix)

def spatial_average_fldas(directory, var):
	mon_dict = {}
	for file in os.listdir(directory):
		filepath = directory + file
		opened_raster = raster(filepath, var)
		day_str = str(int(file.split('.001')[0][-2:]))
		no_nans = opened_raster.matrix[opened_raster.matrix > -9999]
		mon_dict[day_str] = np.mean(no_nans)
		#print(jan_dict[day_str])
	return(mon_dict)


# headers = ['Day Index', 'FLDAS', 'Chirps']
def write_csv_timeseries(csv_outpath, headers, list_day_dicts):
	with open(csv_outpath, mode='w') as fc_chart:
		fc_writer = csv.writer(fc_chart, delimiter=',', quotechar="'")
		fc_writer.writerow(headers)
		fd = list_day_dicts[0]
		for day in fd:
			day_row = [day]
			#day = str(day)
			for day_dict in list_day_dicts:
				try:
					f_entry = '{:.12f}'.format(day_dict[day])
				except:
					f_entry = day_dict[day]
				f_entry = '\"' + f_entry + '\"'
				day_row.append(f_entry)
			#print(jan_entry, feb_entry)
			fc_writer.writerow(day_row)


def write_trend_string(headers, list_day_dicts):
	trend_string = ""
	# Write headers
	for idx, header in enumerate(headers):
		if idx != len(headers)-1:
			trend_string += (str(header)+ ",")
		elif idx == len(headers)-1:
			trend_string += (str(header)+ "\n")
	# Write date rows
	fd = list_day_dicts[0]
	for day in fd:
		day_str = str(day) + ","
		for day_dict in list_day_dicts:
			try:
				f_entry = '{:.12f}'.format(day_dict[day])
			except:
				f_entry = day_dict[day]
			day_str += '\"' + str(f_entry) + '\",'
		trend_string += day_str[:-1] + "\n"
	return(trend_string)

def make_intersection(raster1, raster2):
	# Find intersection
	int_lrx = min(raster1.lrx, raster2.lrx)
	int_lry = max(raster1.lry, raster2.lry)
	int_ulx = max(raster1.ulx, raster2.ulx)
	int_uly = min(raster1.uly, raster2.uly)
	intersection = [int_ulx, int_uly, int_lrx, int_lry]

	# Get new coordinates
	r1 = [raster1.ulx, raster1.uly, raster1.lrx, raster1.lry]
	r2 = [raster2.ulx, raster2.uly, raster2.lrx, raster2.lry]

	gt1 = raster1.geo_trans
	gt2 = raster2.geo_trans

	left1 = int(round((intersection[0]-r1[0])/gt1[1])) # difference divided by pixel dimension
	top1 = int(round((intersection[1]-r1[1])/gt1[5]))
	col1 = int(round((intersection[2]-r1[0])/gt1[1])) - left1 # difference minus offset left
	row1 = int(round((intersection[3]-r1[1])/gt1[5])) - top1

	left2 = int(round((intersection[0]-r2[0])/gt2[1])) # difference divided by pixel dimension
	top2 = int(round((intersection[1]-r2[1])/gt2[5]))
	col2 = int(round((intersection[2]-r2[0])/gt2[1])) - left2 # difference minus new left offset
	row2 = int(round((intersection[3]-r2[1])/gt2[5])) - top2

	# Make subsets
	subset1 = raster1.raster.ReadAsArray(left1,top1,col1,row1)
	subset2 = raster2.raster.ReadAsArray(left2,top2,col2,row2)

	return([subset1, subset2, intersection])

def parse_tiff_tar(tiff_tar):
	tiff_list = []
	if ',' in tiff_tar:
		tiff_tar_list = tiff_tar.split(',')
		for tar in tiff_tar_list:
			if os.path.isdir(tar):
				files = os.listdir(tar)
				for file in files:
					filepath = tar + '/' + file
					tiff_list.append(filepath)
			elif os.path.isfile(tar):
				tiff_list.append(tar)
	return(tiff_list)

def parse_time(timestr, start_or_end):
	if len(timestr) == 8:
		'''YYYYMMDD'''
		yearstr = timestr[0:4]
		monstr = timestr[4:6]
		daystr = timestr[6:]
	elif len(timestr) == 6:
		'''YYYYMM'''
		yearstr = timestr[0:4]
		monstr = timestr[4:]
		if start_or_end == 'start':
			daystr = '01'
		elif start_or_end == 'end':
			daystr = '31'
	elif len(timestr) == 4:
		'''YYYYY'''
		yearstr = timestr
		if start_or_end == 'start':
			monstr = '01'
			daystr = '01'
		elif start_or_end == 'end':
			monstr = '12'
			daystr = '31'
	return([yearstr, monstr, daystr])

def export_to_mongodb(trend_string, trend_name, MONGODB_CONNECTION=MONGODB_CONNECTION):
	mongo_client = pymongo.MongoClient(MONGODB_CONNECTION) # defaults to port 27017
	mongo_db = mongo_client["mintcast"]
	mongo_col = mongo_db["trend"]
	ftmp = mongo_col.find_one({'relative_path': trend_name})
	if ftmp:
		mongo_col.update_one({'relative_path': trend_name}, { '$set': trend_string })
	else:
		mtmp = dict()
		mtmp[trend_name] = trend_string
		mongo_col.insert_one(mtmp)    
		#mongo_col.insert_one({'relative_path': trend_name}, { '$set': trend_string })
#predefine daily time axis
#### combine the two
year = str(2001)
mon_list = [str(x) for x in range(1,11)]
jan_mon = str(1)
feb_mon = str(2)
mar_mon = str(3)
apr_mon = str(4)
may_mon = str(5)
jun_mon = str(6)
jul_mon = str(7)
aug_mon = str(8)
sep_mon = str(9)
oct_mon = str(10)
nov_mon = str(11)
dec_mon = str(12)

jan_days = mar_days = may_days = jul_days = aug_days = oct_days = dec_days = [str(x) for x in range(1,32)]
feb_days = [str(x) for x in range(1,29)]
apr_days = jun_days = sep_days = nov_days = [str(x) for x in range(1,31)]

md = {}
md[jan_mon] = jan_days
md[feb_mon] = feb_days
md[mar_mon] = mar_days
md[apr_mon] = apr_days
md[may_mon] = may_days
md[jun_mon] = jun_days
md[jul_mon] = jul_days
md[aug_mon] = aug_days
md[sep_mon] = sep_days
md[oct_mon] = oct_days
md[nov_mon] = nov_days
md[dec_mon] = dec_days

def fldas_chirps_demo(fldas_jan_path, fldas_feb_path, fldas_var, chirps_path, trend_name, headers):
	fd = {}
	cd = {}
	for mon in md:
		for day in md[mon]:
			datestr = mon + "/" + day + "/" + year
			fd[datestr] = cd[datestr] = "null"
	#### FLDAS 01
	mon_str = '1'
	for file in os.listdir(fldas_jan_path):
		day_str = str(int(file.split('.001')[0][-2:]))
		date_str = mon_str + "/" + day_str + "/" + year
		filepath = fldas_jan_path + file
		opened_raster = raster(filepath, fldas_var)
		no_nans = opened_raster.matrix[opened_raster.matrix > -9999]
		fd[date_str] = np.mean(no_nans) * 86400 * 30

	#### FLDAS 02
	mon_str = '2'
	for file in os.listdir(fldas_feb_path):
		day_str = str(int(file.split('.001')[0][-2:]))
		date_str = mon_str + "/" + day_str + "/" + year
		filepath = fldas_feb_path + file
		opened_raster = raster(filepath, fldas_var)
		no_nans = opened_raster.matrix[opened_raster.matrix > -9999]
		fd[date_str] = np.mean(no_nans) * 86400 * 30

	#### Chirps
	files = [file for file in os.listdir(chirps_path) if file.endswith('clip.tif')]
	files = [file for file in files if file[0:2] != "._"]
	chirps_dict = {}
	day_str = "15"
	for file in files:
		filepath = chirps_path + file
		print(filepath)
		date_str = filepath.split('v1.8.')[1].split('_clip.tif')[0]
		mon_str = str(int(date_str[-2:]))
		year_str = date_str[:4]
		mon_year_str = mon_str + "/" + year_str
		date_str = mon_str + "/" + day_str + "/" + year_str
		opened_raster = raster(filepath)
		no_nans = opened_raster.matrix[opened_raster.matrix > -9999]
		cd[date_str] = np.mean(no_nans)
	
	#### Write CSV file
	list_day_dicts = [fd, cd] #combine dicts in list
	#write_csv_timeseries(csv_outpath, headers, list_day_dicts)
	trend_string = write_trend_string(headers, list_day_dicts)
	print(trend_string)
	export_to_mongodb(trend_string, trend_name)

def run_tiff2(tiff_tar1, tiff_tar2, headers, start_time, end_time, csv_outpath):
	# Parse start and end times
	[start_year, start_mon, start_day] = parse_time(start_time, 'start')
	[end_year, end_mon, end_day] = parse_time(end_time, 'end')
	

	# Parse tiff_tar1 (single file, list of files, directory, or list of directories)
	tiff1_list = parse_tiff_tar(tiff_tar1)
	if len(tiff1_list) == 1:
		print('Null')

	elif len(tiff1_list) > 1:
		print('Null')
	else:
		print("No TIFFs found in tiff_tar1", file = sys.stderr)
		exit(0)

	# Parse tiff_tar2 (single file, list of files, directory, or list of directories)
	tiff2_list = parse_tiff_tar(tiff_tar2)
	if len(tiff2_list) == 1:
		print('Null')
	elif len(tiff2_list) > 1:
		print('Null')
	else:
		print("No TIFFs found in tiff_tar2", file = sys.stderr)
		exit(0)
	return(None)

def run_netcdf(tiff_var, netcdf_tar, netcdf_var, headers, start_time, end_time, csv_outpath):
	return(None)

def run_netcdf2(netcdf_tar1, netcdf_var1, netcdf_tar2, netcdf_var2, headers, start_time, end_time, csv_outpath):
	return(None)

usage = '''
USAGE
	main.py [method] [directory1] ... [directoryx] [netcdf_var] [csv_outpath] [headers]'''

def main():
	method = sys.argv[1]
	if method == "demo":
		fldas_jan_path = sys.argv[2] #".../data/South_Sudan/RawData/Forcing/FLDAS_NOAH01_A_EA_D/2001/01/"
		fldas_feb_path = sys.argv[3] #".../data/South_Sudan/RawData/Forcing/FLDAS_NOAH01_A_EA_D/2001/02/"
		chirps_path = sys.argv[4] #""
		fldas_var = sys.argv[5] #"Rainf_f_tavg"
		trend_name = sys.argv[6] #'./dist/fldas_chirps_2001_timeseries_chart.csv'
		headers = sys.argv[7].split(',') #['Day Index', 'FLDAS', 'Chirps']
		fldas_chirps_demo(fldas_jan_path, fldas_feb_path, fldas_var, chirps_path, trend_name, headers)
	elif method == "tiff2":
		'''Comparison between two TIFF files/directories/list'''
		tiff_tar1 = sys.argv[2]
		tiff_tar2 = sys.argv[3]
		headers = sys.argv[4].split(',')
		start_time = sys.argv[5]
		end_time = sys.argv[6]
		try:
			csv_outpath = sys.argv[7]
		except:
			csv_outpath = dist_path
		run_tiff2(tiff_tar1, tiff_tar2, headers, start_time, end_time, csv_outpath)
	elif method == "netcdf":
		'''Comparison between one netCDF and other files/directories/lists'''
		tiff_tar = sys.argv[2]
		netcdf_tar = sys.argv[3]
		netcdf_var = sys.argv[4]
		headers = sys.argv[5].split('.')
		start_time = sys.argv[6]
		end_time = sys.argv[7]
		try:
			csv_outpath = sys.argv[8]
		except:
			csv_outpath = dist_path
		run_netcdf(tiff_var, netcdf_tar, netcdf_var, headers, start_time, end_time, csv_outpath)

	elif method == "netcdf2":
		'''Comparison between two netCDF files/directories/lists'''
		netcdf_tar1 = sys.argv[2]
		netcdf_var1 = sys.argv[3]
		netcdf_tar2 = sys.argv[4]
		netcdf_var2 = sys.argv[5]
		headers = sys.argv[6].split(',')
		start_time = sys.argv[7]
		end_time = sys.argv[8]
		try:
			csv_outpath = sys.argv[9]
		except:
			csv_outpath = dist_path
		run_netcdf2(netcdf_tar1, netcdf_var1, netcdf_tar2, netcdf_var2, headers, start_time, end_time, csv_outpath)

	else:
		print('No method specified.', file = sys.stderr)
		print(usage, file = sys.stderr)
		exit(0)

if __name__ == '__main__':
	num_args = len(sys.argv)
	if num_args < 4:
		print(usage, file = sys.stderr)
		exit(0)
	main()
