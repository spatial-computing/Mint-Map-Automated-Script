#!/usr/bin/env bash

# export MINTCAST_PATH='/usr/local/bin/mintcast'
oldIFS=$IFS
set +x
if [[ -z "$MINTCAST_PATH" ]]; then
	echo "\033[31;5;148mFirst\033[39m export MINTCAST_PATH=/path/to/mintcast"
	exit 0
fi
# export MINTCAST_PATH='.'

source $MINTCAST_PATH/lib/helper_usage.sh
source $MINTCAST_PATH/lib/helper_parameter.sh
source $MINTCAST_PATH/lib/helper_create_array.sh
source $MINTCAST_PATH/lib/handle_tiff.sh
source $MINTCAST_PATH/lib/handle_tiled_tiff.sh
source $MINTCAST_PATH/lib/handle_tiff_time.sh
source $MINTCAST_PATH/lib/handle_tiff_timeseries.sh
source $MINTCAST_PATH/lib/handle_netcdf.sh
source $MINTCAST_PATH/lib/handle_netcdf_single.sh
source $MINTCAST_PATH/lib/handle_postgresql.sh
source $MINTCAST_PATH/lib/handle_sqlite.sh
source $MINTCAST_PATH/lib/proc_getnetcdf_subdataset.sh

VERSION="$(cat package.json | sed -nE 's/.+@ver.*:.*\"(.*)\".*/\1/p' | tr -d '\r')"

USAGE=""
helper_usage 

if [[ $# -lt 1 ]]; then
    echo "$USAGE"
    exit 0
fi

DATASET_TYPE="tiff"         		# DATASET_TYPE, tiff, netcdf or tiled
QML_FILE=""                 		# QML file path
DATASET_DIR=""              		# If dataset has timeseries or tiled
DATASET_DIR_STRUCTURE=""    		# If DATASET_DIR is set, set structure `{year}/{month}/{day}/*.nc` or `*.zip`
START_TIME=""               		# If dataset has timeseries, start time string, like `2018 05 01`
END_TIME=""                 		# Same as start time
LAYER_NAME=""               		# Layer name could be a string or a json file, as input of tippecanoe
VECTOR_MD5=""						# unique md5hash for each dataset, can be input or generated from standard name
TARGET_JSON_PATH=""         		# Production mode: path to store json files
TILESEVER_PROG=""           		# Path of tileserver program
TILESEVER_PORT="8082"       		# Used by tileserver
TILESEVER_BIND="0.0.0.0"    		# Used by tileserver
DEV_MODE=YES                		# Default is dev mode. Generate all files (mbtiles or json) in dist/.
NO_WEBSITE_UPDATE=NO        		# Only generate tiles in dist/, no json, no restart tileserver
TILED_FILE_EXT="dem.tif"			# for tiled dataset, the suffix and extension of the files to be merged
WITH_QUALITY_ASSESSMENT=NO 			# for tiled dataset, if with --with-quality-assessment, then generate like elevation.num.raster.mbtiles
DATASET_NAME="output" 				# output mbtiles name like -o elevation, output will be elevation.raster.mbtiles and elevation.vector.mbtiles
DISABLE_CLIP="NO"					# do not clip data
FORCE_PROJECTION_FIRST="NO"			# Force projection before standard workflow
GENERATE_NEW_RES="YES"				# Generate new resolution during creation of tiles
GENERATE_RASTER_TILE="YES"			# Generate raster MBTiles as output
GENERATE_VECTOR_TILE="YES"			# Generate vector MBTiles as output
NEW_SSH_KEY="NO"					# Add ssh key 
SSH_USER="vaccaro"					# User-name to ssh/scp into jonsnow (e.g. liboliu, vaccaro, shiwei)
USE_SS_SHAPE="NO"					# Clip using South Sudan boundary shapefile
SS_BOUNDARY="$MINTCAST_PATH/shp/ss.shp" # Default shape file is south sudan
CLIP_BOUNDS="22.4 3.4 37.0 23.2"	# Coordinates for rectangular clipping boundary			
FIRST_FILE="NO"						# Flag for timeseries files (YES for first in series, no otherwise)
TIME_STAMP=""						# Time stamp for TIFF time series
TIME_STEPS=""						# Time steps for TIFF time series
TIME_FORMAT="YYYYMMDD"				# Time format for metadata JSON
SCP_TO_SERVER=""
SCP_TO_SERVER_DEFAULT="root@mintviz.org:/data/"
RESTART_TILESERVER="NO"

CHART_TYPE=""
DATATIME_FORMAT=""

NETCDF_SINGLE_SUBDATASET=""

OUTPUT_DIR_STRUCTURE_FOR_TIMESERIES="" # how netcdf's timeseries mbtiles are stored

COLOR_TABLE=""
COLORMAP_USE_LOADED="NO"
DATAFILE_PATH=""            		# Single file path like tiff

MULTIPLE_THREADS_ENABLED="NO"       # Multiple threads flag

TILESERVER_ROOT="/data"
TILESERVER_PORT="80"
# store mbtiles in a specific folder and read by website
VERBOSE="NO"
if [[ -z "$MINTCAST_IS_ON_SERVER" ]]; then # set it in env
	MINTCAST_IS_ON_SERVER="NO"  # if YES, change TARGET_MBTILES_PATH below	
fi


# TILESERVER_DEFAULT_SERVER="root@mintviz.org"
# TILESERVER_RESTART_CMD="/mintcast/bin/tileserver.sh restart"
# TILESERVER_CHECK_CMD="docker ps"

export TARGET_MBTILES_PATH="$MINTCAST_PATH/dist"  # Production mode: path to store mbtiles files and config files
export TILESTACHE_CONFIG_PATH="$MINTCAST_PATH/dist"

helper_parameter $@

if [[ "$VERBOSE" == "YES" ]]; then
	set -x
fi

echo $START_TIME

if [[ "$DEV_MODE" != 'YES' ]]; then
	if [[ "$MINTCAST_IS_ON_SERVER" == 'YES' ]]; then
		export TARGET_MBTILES_PATH='/data/dist'
		export TILESTACHE_CONFIG_PATH='/data'
	fi
	OUT_DIR=$TARGET_MBTILES_PATH
fi


trap 'echo "Terminating" && trap - SIGTERM && kill -- -$$' SIGINT SIGTERM EXIT
# trap 'kill $(jobs -p)' SIGINT SIGTERM EXIT
# shutdown(){
#  kill $(jobs -p)
#  exit 0
# }
# trap shutdown SIGINT SIGTERM EXIT

if [[ "$DATASET_TYPE" != "single-netcdf" ]]; then
	if [[ -z "$LAYER_NAME" ]]; then
		echo "Please set up -l|--layer-name which is the LAYER_NAME and also part of Layer ID"
		exit 1
	fi
else
	if [[ -z "$OUTPUT_DIR_STRUCTURE_FOR_TIMESERIES" && $DATASET_TYPE != "single-netcdf" ]]; then
		echo "Please set up -z|--output-dir-structure which is how timeseries mbtiles are stored"
		exit 1
	fi
	if [[ -z "$DATASET_DIR"  && $DATASET_TYPE != "single-netcdf" ]]; then
		echo "Please set up -d|--dir which is used for traversal"
		exit 1
	fi	
fi

if [[ -z "$TARGET_JSON_PATH" ]]; then
	export TARGET_JSON_PATH="$MINTCAST_PATH/dist/json"
fi

if [[ ! -d "$TARGET_JSON_PATH" ]]; then
	mkdir -p $TARGET_JSON_PATH
fi

COL_LAYER_TITLE=$(python3 $MINTCAST_PATH/python/macro_string get_layer_title $LAYER_NAME)
COL_LAYER_NAME=$(python3 $MINTCAST_PATH/python/macro_string gen_layer_name $LAYER_NAME)
LAYER_NAME="$COL_LAYER_NAME"
export TEMP_DIR=$MINTCAST_PATH/tmp/$LAYER_NAME

if [[ ! -d "$TEMP_DIR" ]]; then
	mkdir -p $TEMP_DIR
fi

if [[ $DATASET_TYPE == "tiff" ]]; then
	if [[ -z "$START_TIME" ]]; then
		handle_tiff
	else
		MULTIPLE_THREADS_ENABLED="YES"
		handle_tiff_timeseries
	fi
elif [[ $DATASET_TYPE == "tiled" ]]; then
	handle_tiled_tiff
elif [[ $DATASET_TYPE == "netcdf" ]]; then
	# proc_getnetcdf_subdataset $DATAFILE_PATH
	MULTIPLE_THREADS_ENABLED="YES"
	handle_netcdf
	# echo "hi"
	# exit
elif [[ $DATASET_TYPE == "single-netcdf" ]]; then
	handle_netcdf_single
elif [[ $DATASET_TYPE == "tiff-time" ]]; then
	handle_tiff_time
elif [[ $DATASET_TYPE == "csv" ]]; then
	python3 $MINTCAST_PATH/python/macro_store_csv "$CHART_TYPE" "$COL_LAYER_TITLE" "$VECTOR_MD5" "$DATAFILE_PATH"

	if [[ "$VERBOSE" == "YES" ]]; then
		set +x
	fi
	IFS=$oldIFS
	exit 0
else
	echo "$DATASET_TYPE is an invalid dataset type." 
	echo "Valid choices include: tiff, tiled, tiff-time, netcdf, and single-netcdf"
	exit 1
fi

# if [[ $DATASET_TYPE == "single-netcdf" ]]; then 
if [[ "$DEV_MODE" != "YES" ]]; then
	# save raster
	if [[ "$MULTIPLE_THREADS_ENABLED" == "YES" ]]; then
		COL_LEGEND_SUM=""
		COL_COLORMAP_SUM=""
		for (( idx = 0; idx < $TOTAL_FILES_COUNT; idx++ )); do
			source $TEMP_DIR/sync_$idx.sh
			if [[ -z "$COL_LEGEND_SUM" ]]; then
				COL_LEGEND_SUM="$COL_LEGEND"
				COL_COLORMAP_SUM="$COL_COLORMAP"
			# else
			# 	COL_LEGEND_SUM=$COL_LEGEND_SUM"|""$COL_LEGEND"
			# 	COL_COLORMAP_SUM=$COL_COLORMAP_SUM"|""$COL_COLORMAP"
			fi
		done
		COL_LEGEND="$COL_LEGEND_SUM"
		COL_COLORMAP="$COL_COLORMAP_SUM"
	fi
	COL_RASTER_OR_VECTOR_TYPE="raster"
	MBTILES_FILEPATH=$RASTER_MBTILES
	#handle_sqlite
	handle_postgresql

	# save vector
	COL_RASTER_OR_VECTOR_TYPE="vector"
	MBTILES_FILEPATH=$VECTOR_MBTILES

	#handle_sqlite
	handle_postgresql

	python3 $MINTCAST_PATH/python/macro_gen_web_json update-all 
	#CKAN_URL=$(python3 $MINTCAST_PATH/python/macro_upload_ckan get "$TARGET_JSON_PATH/$COL_JSON_FILENAME")
	#echo $CKAN_URL
	# update database
	#echo "TARGET_JSON_PATH: $TARGET_JSON_PATH"
	#CKAN_URL=""
	#python3 $MINTCAST_PATH/python/macro_postgres_curd update layer \
	#"ckan_url='$CKAN_URL'" \
	#"layerid='$Cmacro_tileserver_configOL_LAYER_ID'"
	python3 $MINTCAST_PATH/python/macro_gen_web_json update-config

	# elif [[ $DATASET_TYPE == "netcdf" || $DATASET_TYPE == "single-netcdf" ]]; then
	# 	MBTILES_DIR=$(dirname "${RASTER_MBTILES}")
	# 	echo "MBTILES_DIR: $MBTILES_DIR"
	# 	MBTILES_ARRAY=($MBTILES_DIR/*.mbtiles)
	# 	for ((i=0; i<${#MBTILES_ARRAY[@]}; i++)); do
	# 		MBTILES_FILEPATH=${MBTILES_ARRAY[i]}
	# 		echo "MBTILES_FILEPATH: $MBTILES_FILEPATH"
	# 		if [[ $MBTILES_FILEPATH = *raster* ]]; then
	# 			COL_RASTER_OR_VECTOR_TYPE="raster"
	# 		elif [[ $MBTILES_FILEPATH = *vector* ]]; then
	# 			COL_RASTER_OR_VECTOR_TYPE="vector"
	# 		fi
	# 		handle_sqlite
	# 		python3 $MINTCAST_PATH/python/macro_gen_web_json update-all 
	# 		CKAN_URL=$(python3 $MINTCAST_PATH/python/macro_upload_ckan "$TARGET_JSON_PATH/$COL_JSON_FILENAME")
	# 		echo $CKAN_URL
	# 		# update database
	# 		python3 $MINTCAST_PATH/python/macro_sqlite_curd update layer \
	# 		"ckan_url='$CKAN_URL'" \
	# 		"layerid='$COL_LAYER_ID'"
	# 		python3 $MINTCAST_PATH/python/macro_gen_web_json update-config
	# 	done	
	# fi


	# rm -f "$MINTCAST_PATH/tmp/*"


	# python3 $MINTCAST_PATH/python/macro_tileserver_config "$TILESERVER_ROOT" "$TILESERVER_PORT"
	python3 $MINTCAST_PATH/python/macro_tilestache_config "$TILESERVER_ROOT" "yes"

fi

# run mintcast on **local** and copy to server
	# --dev-mode-off --tile-server-root "./" --scp-to-default-server  
# run mintcast on server and restart tileserver
	# --dev-mode-off --target-mbtiles-path "/data/dist" --tile-server-root ""
IFS=$oldIFS
if [[ "$DEV_MODE" != "YES" ]]; then
	if [[ "$MINTCAST_IS_ON_SERVER" == "NO" ]]; then
		if [[ ! -z "$SCP_TO_SERVER" ]]; then
			echo "Running scp -r $OUT_DIR $SCP_TO_SERVER ..."
			scp -r $OUT_DIR $SCP_TO_SERVER"/dist/"
			echo "Running scp config/config.json $SCP_TO_SERVER ..."
			scp config/tilestache.json $SCP_TO_SERVER
		fi
	fi
	
	echo "Deleting $TEMP_DIR ..."
	rm -rf $TEMP_DIR
	# "$MINTCAST_PATH/tmp/$LAYER_NAME"

	# if [[ "$RESTART_TILESERVER" == "YES" ]]; then
	# 	echo "Restarting tileserver ..." 
	# 	if [[ ! -z "$SCP_TO_SERVER" ]]; then
	# 		ssh $TILESERVER_DEFAULT_SERVER "$TILESERVER_RESTART_CMD"
	# 		ssh $TILESERVER_DEFAULT_SERVER "$TILESERVER_CHECK_CMD"
	# 	else
	# 		sh $MINTCAST_PATH/bin/tileserver.sh restart
	# 	fi
	# fi
fi

# if [[ "$RESTART_TILESERVER" != "YES" ]]; then
# 	if [[ "$DEV_MODE" != "YES" ]]; then
# 		echo "\033[31;5;148mRun on server needed\033[39m: /mintcast/bin/tileserver.sh restart"
# 	else
# 		echo "\033[31;5;148mRun on local needed\033[39m: $MINTCAST_PATH/bin/tileserver.sh restart"
# 	fi
# fi
# # scp MBtiles and json to jonsnow
# if [[ "$DEV_MODE" != "YES" ]]; then
# 	#JONSNOW_STR="$SSH_USER@jonsnow.usc.edu"
# 	ROOT_STR="root@jonsnow.usc.edu"
# 	JONSNOW_MBTILES="/home/mint-webmap/mbtiles/"
# 	JONSNOW_JSON="/home/mint-webmap/json/"
# 	HOME_DIR="/home/$SSH_USER/"
# 	if [[ $NEW_SSH_KEY == "YES" ]]; then
# 		#ssh-copy-id $JONSNOW_STR
# 		ssh-copy-id -i $ROOT_STR

# 	fi
# 	#RASTER_NAME=$(basename $RASTER_MBTILES)
# 	#VECTOR_NAME=$(basename $VECTOR_MBTILES)
# 	#scp $RASTER_MBTILES $JONSNOW_STR:$HOME_DIR
# 	scp $RASTER_MBTILES $ROOT_STR:$JONSNOW_MBTILES
# 	scp $VECTOR_MBTILES $ROOT_STR:$JONSNOW_MBTILES
# 	scp $TARGET_JSON_PATH/$COL_JSON_FILENAME $ROOT_STR:$JONSNOW_JSON
# 	#ssh -t $JONSNOW_STR "sudo mv $RASTER_MBTILES $JONSNOW_MBTILES"
# fi

# # restart tile server
# nohup $MINTCAST_PATH/bin/tileserver-daemon.sh restart $TILESEVER_PORT &

#remove intermediate files
# rm -f $TEMP_DIR/*
if [[ "$VERBOSE" == "YES" ]]; then
	set +x
fi

IFS=$oldIFS
