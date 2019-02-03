#!/usr/bin/env bash

source $MINTCAST_PATH/lib/proc_getnetcdf_subdataset.sh
source $MINTCAST_PATH/lib/handle_tiff.sh

handle_netcdf(){
	# python3 $MINTCAST_PATH/python/macro_traversal "/Users/liber/Documents/South_Sudan/RawData/Forcing/FLDAS_NOAH01_A_EA_D/" "{year}/{month}/*.nc" "2001 01" "2001 03"
	NETCDF_FILES_STRING=$(python3 $MINTCAST_PATH/python/macro_traversal path "$DATASET_DIR/" "$DATASET_DIR_STRUCTURE" "$START_TIME" "$END_TIME" "$DATATIME_FORMAT")


	TIME_STEPS=$(python3 $MINTCAST_PATH/python/macro_traversal step "$DATASET_DIR/" "$DATASET_DIR_STRUCTURE" "$START_TIME" "$END_TIME" "$DATATIME_FORMAT")
    # printf "%s\n" "$NETCDF_FILES_STRING" | {
    # 	while IFS=$'\n' read -r line_data; do
    #         NETCDF_FILES+=("$line_data")
    # 	done
    # }

	IFS=$'\n'
	NETCDF_FILES=($NETCDF_FILES_STRING)

	let TOTAL_FILES_COUNT=${#NETCDF_FILES[@]}
	if [[ $TOTAL_FILES_COUNT -eq 0 ]]; then
		>&2 echo "Cannot find files according to time steps; "
		>&2 echo "DATASET directory structure is wrong"
		>&2 echo "(try use tar vf or zip -l test it before register)."
		exit 1
	fi
	SUBDATASETS_ARRAY=()
	SUBDATASET_LAYERS_ARRAY=()
	LAYER_INDEX=''
	let index=0
	
	for netcdf_file in "${NETCDF_FILES[@]}"; do
		# echo $netcdf_file
		proc_getnetcdf_subdataset "$netcdf_file"
		PARTIAL_PATH=$(python3 $MINTCAST_PATH/python/macro_path diff "$netcdf_file" "$DATASET_DIR")
		echo "PARTIAL_PATH: $PARTIAL_PATH"

		for subset_tiff in "${SUBDATASETS_ARRAY[@]}"; do
			echo "subset_tiff: $subset_tiff"
			DATAFILE_PATH="$subset_tiff"
			if [[ -z "$LAYER_NAME" ]]; then
				LAYER_NAME="${SUBDATASET_LAYERS_ARRAY[$index]}"
			fi
			OUT_DIR="$TARGET_MBTILES_PATH/$PARTIAL_PATH"
			echo "OUT_DIR: $OUT_DIR"
			LAYER_ID_SUFFIX=$(python3 $MINTCAST_PATH/python/macro_string path_to_suffix $PARTIAL_PATH)
			echo "LAYER_ID_SUFFIX: $LAYER_ID_SUFFIX"

			handle_tiff &
			index=$((index+1))
			LAYER_INDEX="$index"

		    if [[ $(( $index % $THREADS_NUM )) -eq 1 ]]; then
		    	echo "$((index-1)) milestone wait"
		    	wait
		    	echo "$index milestone start"
		    fi
		done

		# reset out dir
		OUT_DIR="$TARGET_MBTILES_PATH"$(python3 $MINTCAST_PATH/python/macro_path toplevel $PARTIAL_PATH)


		# if [[ "$DEV_MODE" != "YES" ]]; then
		# 	if [[ "$GENERATE_NEW_RES" == "YES" ]]; then
		# 		echo "Deleting $MINTCAST_PATH/tmp/* ..."
		# 		rm -rf "$MINTCAST_PATH/tmp/"*
		# 	fi
		# fi
		
	done
	wait
	echo "Multiple jobs have done."
	# xargs -I % proc_getnetcdf_subdataset %
}
# test
# DATASET_NAME='elevation' MINTCAST_PATH='.' DATASET_DIR='/Users/liber/Documents/South_Sudan/RawData/Forcing/FLDAS_NOAH01_A_EA_D/' DATASET_DIR_STRUCTURE='{year}/{month}/*.nc' START_TIME='2001 01' END_TIME='2001 03' ./lib/handle_netcdf.sh
# handle_netcdf