#!/usr/bin/env bash

source $MINTCAST_PATH/lib/handle_tiff.sh

handle_tiff_timeseries(){
	# python3 $MINTCAST_PATH/python/macro_traversal "/Users/liber/Documents/South_Sudan/RawData/Forcing/FLDAS_NOAH01_A_EA_D/" "{year}/{month}/*.nc" "2001 01" "2001 03"
	TIFF_FILES_STRING=$(python3 $MINTCAST_PATH/python/macro_traversal path "$DATASET_DIR/" "$DATASET_DIR_STRUCTURE" "$START_TIME" "$END_TIME" "$DATATIME_FORMAT")

	TIME_STEPS=$(python3 $MINTCAST_PATH/python/macro_traversal step "$DATASET_DIR/" "$DATASET_DIR_STRUCTURE" "$START_TIME" "$END_TIME" "$DATATIME_FORMAT")
	echo $TIME_STEPS
	IFS=$'\n'
	TIFF_FILES=($TIFF_FILES_STRING)
	
	echo ${TIFF_FILES[@]}
	let index=0

	for geotiff_file in "${TIFF_FILES[@]}"; do
		# echo $netcdf_file
		PARTIAL_PATH=$(python3 $MINTCAST_PATH/python/macro_path diff "$geotiff_file" "$DATASET_DIR")
		echo "##### $geotiff_file"
		LAYER_NAME="$LAYER_NAME"
		DATAFILE_PATH="$geotiff_file"
		OUT_DIR="$TARGET_MBTILES_PATH/$OUTPUT_DIR_STRUCTURE_FOR_TIMESERIES/$PARTIAL_PATH"
		LAYER_ID_SUFFIX=$(python3 $MINTCAST_PATH/python/macro_string path_to_suffix $PARTIAL_PATH)

		echo "######### $LAYER_ID_SUFFIX ### $PARTIAL_PATH"
		
		handle_tiff
		index=$((index+1))
		LAYER_INDEX="$index"
		# rm "$MINTCAST_PATH/tmp/*"
	done
	# xargs -I % proc_getnetcdf_subdataset %
}
# test
# DATASET_NAME='elevation' MINTCAST_PATH='.' DATASET_DIR='/Users/liber/Documents/South_Sudan/RawData/Forcing/FLDAS_NOAH01_A_EA_D/' DATASET_DIR_STRUCTURE='{year}/{month}/*.nc' START_TIME='2001 01' END_TIME='2001 03' ./lib/handle_netcdf.sh
# handle_netcdf

