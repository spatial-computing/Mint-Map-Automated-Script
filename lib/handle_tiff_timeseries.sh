#!/usr/bin/env bash

source $MINTCAST_PATH/lib/handle_tiff.sh

handle_tiff_timeseries(){
	# python3 $MINTCAST_PATH/python/macro_traversal/main.py "/Users/liber/Documents/South_Sudan/RawData/Forcing/FLDAS_NOAH01_A_EA_D/" "{year}/{month}/*.nc" "2001 01" "2001 03"
	TIFF_FILES_STRING=$(python3 $MINTCAST_PATH/python/macro_traversal/main.py "$DATASET_DIR/" "$DATASET_DIR_STRUCTURE" "$START_TIME" "$END_TIME" "$DATATIME_FORMAT")
	
    # printf "%s\n" "$NETCDF_FILES_STRING" | {
    # 	while IFS=$'\n' read -r line_data; do
    #         NETCDF_FILES+=("$line_data")
    # 	done
    # }
	IFS=$'\n'
	TIFF_FILES=($TIFF_FILES_STRING)
	for geotiff_file in "${TIFF_FILES[@]}"; do
		# echo $netcdf_file
		PARTIAL_PATH=$(python3 $MINTCAST_PATH/python/macro_path/main.py diff "$geotiff_file" "$DATASET_DIR")
		echo $geotiff_file
		DATAFILE_PATH="$geotiff_file"
		OUT_DIR="$MINTCAST_PATH/dist/$OUTPUT_DIR_STRUCTURE_FOR_TIMESERIES/$PARTIAL_PATH"
		LAYER_ID_SUFFIX=$(python3 $MINTCAST_PATH/python/macro_string/main.py path_to_suffix $PARTIAL_PATH)
		handle_tiff
		# rm "$MINTCAST_PATH/tmp/*"
	done
	# xargs -I % proc_getnetcdf_subdataset %
}
# test
# DATASET_NAME='elevation' MINTCAST_PATH='.' DATASET_DIR='/Users/liber/Documents/South_Sudan/RawData/Forcing/FLDAS_NOAH01_A_EA_D/' DATASET_DIR_STRUCTURE='{year}/{month}/*.nc' START_TIME='2001 01' END_TIME='2001 03' ./lib/handle_netcdf.sh
# handle_netcdf