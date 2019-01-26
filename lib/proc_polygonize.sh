#!/usr/bin/env bash

### proc_polygonize.sh
# Polygonize TIFF and add layer and value names using gdal_polygonize.py
### Inputs:
# 1) Input file, 2) Output file, 3) Layer name
### Outputs:
# GeoJSON file containing polygonized data
### Procedure:
# - Polygonize with gdal_polygonize.py

# Polygonize data:
proc_polygonize () {
	if [[ -f "$2" ]]; then
		rm -f "$2"
	fi

	POLYGONIZED="python3 $MINTCAST_PATH/python/gdal_polygonize.py $1 `#Input filename` -f geojson $POLYGONIZE_FLOAT_FLAG $2 `#Output filename` '$3' `#Layer name` 'value'"
	echo "$POLYGONIZED"
	eval "$POLYGONIZED"

	
	if [[ $? != 0 ]]; then
		echo "gdal_polygonize.py failed in proc_polygonize.sh  Exiting script."
		exit 1
	fi
}