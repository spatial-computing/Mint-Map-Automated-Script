#### temporal_aggregated_diff.ipynb
# 1) Take monthly average
# 2) Find difference
# 3) Export as GeoTIFF
# 4) Run mintcast to make MBTiles

# Datasets used:
# FLDAS01:Rainf_f_tavg
# FLDAS02:Rainf_f_tavg

from osgeo import gdal, osr
import os
import subprocess
import numpy as np
from matplotlib import pyplot as plt
from copy import copy

MINTCAST_PATH = os.environ.get('MINTCAST_PATH')
dist_path = MINTCAST_PATH + '/dist/'
temp_path = os.environ.get('TEMP_DIR') + "/" #MINTCAST_PATH + '/tmp/'


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

def temporal_average(directory, var):
    for idx, file in enumerate(os.listdir(directory)):
        file_path = directory + file
        opened_raster = raster(file_path, var)
        if idx == 0:
            template = copy(opened_raster)
            running_nobs = (template.matrix == -9999)*1
            running_no_nans = template.matrix
            running_no_nans[running_nobs] = 0
            #running_sum = template.matrix
        else:
            nobs = (opened_raster.matrix == -9999)*1
            running_nobs += nobs
            no_nans = opened_raster.matrix
            no_nans[nobs] = 0
            running_no_nans += no_nans
            #template.matrix += opened_raster.matrix
        del opened_raster
        #count += 1
    running_nobs[running_nobs == 0] = 1
    template.matrix = running_no_nans/running_nobs
    return(template)

def regrid_raster(raster1, raster2):
	if raster1.cell_area > raster2.cell_area:
		big = raster1
		little = raster2
	else:
		big = raster2
		little = raster1
    x_big = big.geo_trans[1]
    print(x_big)
    y_big = big.geo_trans[5]
    print(y_big)
    new_filename = little.filename.split(".")[0] + "_resize.tif"
    print(new_filename)
    new_filepath = os.path.join(little.dir, new_filename)
    print(new_filepath)
    warp_command = "gdalwarp " + "-tr " + str(x_big) + " " + str(y_big) + " " + little.filepath + " " + new_filepath
    print(warp_command)
    subprocess.call(warp_command, shell=True)
    if raster1.cell_area > raster2.cell_area:
    	return([raster1, raster(new_filepath)])
    else:
    	return([raster(new_filepath), raster2])


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

def extract_netcdf_var(raster, netcdf_var):
	nrows, ncols = raster.matrix.shape
	dstfile = raster1.filepath.split('.tiff')[0] + netcdf_var + '.tiff'
	driver = gdal.GetDriverByName('Gtiff')
	dataset = driver.Create(dstfile, ncols, nrows, 1, gdal.GDT_Float32)
	dataset.SetGeoTransform(raster.geo_trans)
	srs = osr.SpatialReference()                
	srs.ImportFromEPSG(4326)
	dataset.SetProjection(srs.ExportToWkt())
	dataset.GetRasterBand(1).WriteArray(raster.matrix)
	dataset = None
	return(var_file)

def calculate_difference(array1, array2, intersect_obs):
	diff = copy(array1)
	diff[:][:] = -9999
	diff[intersect_obs] = array2[intersect_obs] - array1[intersect_obs]
	return(diff)

def fldas_chirps_demo(fldas_directory, netcdf_var, chirps_path, out_path):
	## FLDAS
	fldas01 = temporal_average(fldas_directory, netcdf_var)
	fldas01_obs = fldas01.matrix != -9999
	fldas01.matrix[fldas01_obs] = fldas01.matrix[fldas01_obs] * 86400 * 30
	#  Extract netcdf variable and save it as its own GeoTIFF
	fldas_var_file = extract_netcdf_var(fldas01, netcdf_var)
	fldas01 = raster(fldas_var_file)
	## CHIRPS
	chirps01 = raster(chirps_path)
	## Regrid rasters
	[fldas01_regrid, chirps01_regrid] = regrid_raster(fldas01, chirps01)
	## Get intersection
	[fldas01_int, chirps01_int] = make_intersection(fldas01_regrid, chirps01_regrid)
	# Select non-missing points
	fldas01_obs = fldas01_int != -9999
	chirps01_obs = chirps01_int != -9999
	intersect_obs = np.multiply(fldas01_obs, chirps01_obs)
	## Calculate difference
	diff = calculate_difference(fldas01_int, chirps01_int, intersect_obs)
	## Write to GeoTIFF
	nrows, ncols = diff.shape
	[int_ulx, int_uly, int_lrx, int_lry] = intersection
	geo_trans = (int_ulx, fldas01.geo_trans[1], fldas01.geo_trans[2], int_uly, fldas01.geo_trans[4], fldas01.geo_trans[5])
	dstfile = outpath + 'CHIRPS01_FLDAS01_difference_2001.tiff'
	driver = gdal.GetDriverByName('Gtiff')
	dataset = driver.Create(dstfile, ncols, nrows, 1, gdal.GDT_Float32)
	dataset.SetGeoTransform(geo_trans)
	srs = osr.SpatialReference()                
	srs.ImportFromEPSG(4326)
	dataset.SetProjection(srs.ExportToWkt())
	dataset.GetRasterBand(1).WriteArray(diff)
	dataset = None
	## Encode missing values
	dstfile2 = dstfile.split('.')[0] + '_nomiss.tiff'
	translate = "gdal_translate -a_nodata -9999 -of GTiff " 
	translate += dstfile + " " + dstfile2
	translate
	subprocess.call(translate, shell=True)
	## Generate map tiles
	mint_command = "mintcast " + dstfile2 + " -t tiff -l Rainf_f_tavg_diff_CHIRPS01_FLDAS01 --disable-clip" 
	subprocess.call(mint_command, shell=True)

def run_tiff2(tiff_tar1, tiff_tar2, names, outpath):
	return(None)
def run_netcdf(tiff_tar, netcdf_tar, netcdf_var, names, outpath):
	return(None)

def run_netcdf2(netcdf_tar1, netcdf_var1, netcdf_tar2, netcdf_var2, names, outpath):
	return(None)

usage = '''
USAGE
	main.py [method] [directory1] [directory2] [netcdf_var] '''

def main():
	method = sys.argv[1]
	if method == "demo":
		fldas_directory = sys.argv[2]
		netcdf_var = sys.argv[3]	# rainfall_var = "Rainf_f_tavg"
		chirps_path = sys.argv[4]
		outpath = sys.argv[5]
		fldas_chirps_demo(fldas_directory, netcdf_var, chirps_path, outpath)
	elif method == "tiff2":
		'''TIFF vs TIFF'''
		tiff_tar1 = sys.argv[2]
		tiff_tar2 = sys.argv[3]
		names = sys.argv[4].split(',')
		try:
			outpath = sys.argv[5]
		except:
			outpath = dist_path
		run_tiff2(tiff_tar1, tiff_tar2, names, outpath)
	elif method == "netcdf":
		'''TIFF vs NetCDF'''
		tiff_tar = sys.argv[2]
		netcdf_tar = sys.argv[3]
		netcdf_var = sys.argv[4]
		names = sys.argv[5].split(',')
		try:
			outpath = sys.argv[6]
		except:
			outpath = dist_path
		run_netcdf(tiff_tar, netcdf_tar, netcdf_var, names, outpath)

	elif method == "netcdf2":
		'''NetCDF vs NetCDF'''
		netcdf_tar1 = sys.argv[2]
		netcdf_var1 = sys.argv[3]
		netcdf_tar2 = sys.argv[4]
		netcdf_var2 = sys.argv[5]
		names = sys.argv[6].split(',')
		try:
			outpath = sys.argv[7]
		except:
			outpath = dist_path
		run_netcdf2(netcdf_tar1, netcdf_var1, netcdf_tar2, netcdf_var2, names, outpath)
	else:
		print('No method specified.', file = sys.stderr)
		print(usage, file = sys.stderr)
		exit(0)

if __name__ == "__main__":
	num_args = len(sys.argv)
	if num_args < 4:
		print(usage, file = sys.stderr)
		exit(0)
	main()

