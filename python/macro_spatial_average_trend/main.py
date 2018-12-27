#!/usr/bin/env python3

from osgeo import gdal, osr
import os, sys
import subprocess
import numpy as np
from matplotlib import pyplot as plt
from copy import copy
import csv

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
		            f_entry = '{:.12f}'.format(fd[day])
		        except:
		            f_entry = fd[day]
    	        f_entry = '\"' + f_entry + '\"'
		        day_row.append(f_entry)
	        #print(jan_entry, feb_entry)
	        fc_writer.writerow(day_row)


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

def fldas_chirps_demo(fldas_jan_path, fldas_feb_path, fldas_var, chirps_path, csv_outpath, headers):
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
	    filepath = jan_path + file
	    opened_raster = raster(filepath, fldas_var)
	    no_nans = opened_raster.matrix[opened_raster.matrix > -9999]
	    fd[date_str] = np.mean(no_nans) * 86400 * 30

	#### FLDAS 02
	mon_str = '2'
	for file in os.listdir(fldas_feb_path):
	    day_str = str(int(file.split('.001')[0][-2:]))
	    date_str = mon_str + "/" + day_str + "/" + year
	    filepath = feb_path + file
	    opened_raster = raster(filepath, rainfall_var)
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
	write_csv_timeseries(csv_outpath, headers, list_day_dicts):

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
		csv_outpath = sys.argv[6] #'./dist/fldas_chirps_2001_timeseries_chart.csv'
		headers = sys.argv[7].split(',') #['Day Index', 'FLDAS', 'Chirps']
		fldas_chirps_demo(fldas_jan_path, fldas_feb_path, fldas_var, chirps_path, csv_outpath, headers)

if __name__ == '__main__':
	num_args = len(sys.argv)
	if num_args < 4:
		print(usage, file = sys.stderr)
		exit(0)
	main()
