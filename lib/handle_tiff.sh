#!/usr/bin/env bash

### handle_tiff.sh
# Complete workflow for generating raster and vector tiles from TIFFs.
### Inputs:
# 1) Input filepath, 2) Layer name

### TO DO: figure out what to use for no data value depending on data type

# Source functions:
source $MINTCAST_PATH/lib/check_projection.sh
source $MINTCAST_PATH/lib/check_type.sh
source $MINTCAST_PATH/lib/proc_clip.sh
source $MINTCAST_PATH/lib/proc_newres.sh
source $MINTCAST_PATH/lib/proc_tif2mbtiles.sh
source $MINTCAST_PATH/lib/proc_gdaladdo.sh
source $MINTCAST_PATH/lib/proc_gdaldem.sh
source $MINTCAST_PATH/lib/proc_polygonize.sh
source $MINTCAST_PATH/lib/proc_geojson2mbtiles.sh

handle_tiff(){
	# Parse arguments from mintcast.sh:
	INPUT=$DATAFILE_PATH
	LAYER_NAME="$LAYER_NAME"

	# Hard-coded paths (passed from mintcast.sh?):
	if [[ -z "$OUT_DIR" ]]; then
		OUT_DIR="$MINTCAST_PATH/dist"
	fi
	if [[ ! -d "$OUT_DIR" ]]; then
		mkdir -p "$OUT_DIR"
	fi
	if [[ -z "$TEMP_DIR" ]]; then
		TEMP_DIR="$MINTCAST_PATH/tmp"
	fi
	if [[ ! -d "$TEMP_DIR" ]]; then
		mkdir -p "$TEMP_DIR"
	fi

	#OUT_DIR=$MINTCAST_PATH/dist
	#TEMP_DIR=$OUT_DIR
	#TEMP_DIR=$MINTCAST_PATH/tmp

	# Remove path from inpust:
	echo "INPUT: $INPUT"
	FILENAME=$(basename $INPUT)

	# Set names for intermediary and output files:
	CLIP_OUT=$TEMP_DIR/${FILENAME%.*}_clip.tif
	PROJ_OUT=${CLIP_OUT%.*}_proj.tif
	RES_OUT=${PROJ_OUT%.*}_newres.tif
	COLOR_OUT=${RES_OUT%.*}_color.tif
	POLY_OUT=${PROJ_OUT%.*}_poly.geojson
	if [[ "$MULTIPLE_THREADS_ENABLED" == "YES" ]]; then
		CLIP_OUT=$TEMP_DIR/${FILENAME%.*}"_"$index"_clip.tif"
		PROJ_OUT=${CLIP_OUT%.*}"_"$index"_proj.tif"
		RES_OUT=${PROJ_OUT%.*}"_"$index"_newres.tif"
		COLOR_OUT=${RES_OUT%.*}"_"$index"_color.tif"
		POLY_OUT=${PROJ_OUT%.*}"_"$index"_poly.geojson"
	fi
	if [[ -z "$LAYER_ID_SUFFIX" ]]; then
		LAYER_ID_SUFFIX=''
	fi

	if [[ -z "$LAYER_INDEX" ]]; then
		LAYER_INDEX=''
	fi

	if [[ -z "$FIRST_RASTER_LAYER_ID" ]]; then
		FIRST_RASTER_LAYER_ID=''
	fi
	echo "VECTOR_MD5: $VECTOR_MD5"
	VECTOR_LAYER_ID=$(python3 $MINTCAST_PATH/python/macro_string layer_name_to_layer_id $LAYER_NAME$LAYER_ID_SUFFIX vector pbf)
	### CHANGE THE LINE BELOW TO GET THE PROPER MD5 (AFTER INTEGRATING WITH THE DATA CATALOG)
	if [[ -z $VECTOR_MD5 ]]; then
		export VECTOR_LAYER_ID_MD5=$(python3 $MINTCAST_PATH/python/macro_md5 $VECTOR_LAYER_ID)
	elif [[ ! -z $VECTOR_MD5 ]]; then
		export VECTOR_LAYER_ID_MD5=$VECTOR_MD5
	fi

	#echo "VECTOR_LAYER_ID_MD5: $VECTOR_LAYER_ID_MD5"
	VECTOR_MBTILES=$OUT_DIR/$VECTOR_LAYER_ID.mbtiles
	echo "VECTOR_MBTILES: $VECTOR_MBTILES"
	if [[ -f $VECTOR_MBTILES ]]; then
		rm -f $VECTOR_MBTILES
	fi

	if [[ ! -z "$LAYER_INDEX" ]]; then
		VECTOR_LAYER_ID_MD5="$VECTOR_LAYER_ID_MD5""_""$LAYER_INDEX"
	fi

	
	RASTER_LAYER_ID=$(python3 $MINTCAST_PATH/python/macro_string layer_name_to_layer_id $LAYER_NAME$LAYER_ID_SUFFIX raster png)
	#echo "RASTER_LAYER_ID: $RASTER_LAYER_ID"
	### CHANGE THE LINE BELOW TO GET THE PROPER MD5 (AFTER INTEGRATING WITH THE DATA CATALOG)
	if [[ -z $VECTOR_MD5 ]]; then
		export RASTER_LAYER_ID_MD5=$(python3 $MINTCAST_PATH/python/macro_md5 $RASTER_LAYER_ID)
	elif [[ ! -z $VECTOR_MD5 ]]; then
		export RASTER_LAYER_ID_MD5=$(python3 $MINTCAST_PATH/python/macro_md5 $VECTOR_LAYER_ID_MD5)
		echo "RASTER_LAYER_ID_MD5: $RASTER_LAYER_ID_MD5"
	fi

	if [[ -z "$LAYER_INDEX" ]]; then
		export FIRST_RASTER_LAYER_ID="$RASTER_LAYER_ID_MD5"
	fi
	#echo "RASTER_LAYER_ID_MD5: $RASTER_LAYER_ID_MD5"
	RASTER_MBTILES=$OUT_DIR/$RASTER_LAYER_ID.mbtiles
	echo "RASTER_MBTILES: $RASTER_MBTILES"
	if [[ -f $RASTER_MBTILES ]]; then
		rm -f $RASTER_MBTILES
	fi
	
	if [[ "$DEV_MODE" != "YES" ]]; then
		#HAS_LAYER=$(python3 $MINTCAST_PATH/python/macro_sqlite_curd has_tileserver_config $RASTER_LAYER_ID)
		HAS_LAYER=$(python3 $MINTCAST_PATH/python/macro_postgres_curd has_tileserver_config $RASTER_LAYER_ID_MD5)
		if [[ "$HAS_LAYER" = "None" ]]; then
			#python3 $MINTCAST_PATH/python/macro_sqlite_curd insert tileserverconfig \
			python3 $MINTCAST_PATH/python/macro_postgres_curd insert tileserverconfig \
				"layerid, mbtiles, md5, layer_name" \
				"'$RASTER_LAYER_ID', '$RASTER_MBTILES', '$RASTER_LAYER_ID_MD5', '$COL_LAYER_NAME'"

		else
			#python3 $MINTCAST_PATH/python/macro_sqlite_curd update tileserverconfig \
			python3 $MINTCAST_PATH/python/macro_postgres_curd update tileserverconfig \
				"layerid='$RASTER_LAYER_ID', mbtiles='$RASTER_MBTILES', md5='$RASTER_LAYER_ID_MD5', layer_name='$COL_LAYER_NAME'" \
				"id=$HAS_LAYER"
			python3 $MINTCAST_PATH/python/macro_tilestache_cache flush '$RASTER_LAYER_ID_MD5'
		fi

		#HAS_LAYER=$(python3 $MINTCAST_PATH/python/macro_sqlite_curd has_tileserver_config $VECTOR_LAYER_ID)
		HAS_LAYER=$(python3 $MINTCAST_PATH/python/macro_postgres_curd has_tileserver_config $VECTOR_LAYER_ID_MD5)
		if [[ "$HAS_LAYER" = "None" ]]; then
			#python3 $MINTCAST_PATH/python/macro_sqlite_curd insert tileserverconfig \
			python3 $MINTCAST_PATH/python/macro_postgres_curd insert tileserverconfig \
				"layerid, mbtiles, md5, layer_name" \
				"'$VECTOR_LAYER_ID', '$VECTOR_MBTILES', '$VECTOR_LAYER_ID_MD5', '$COL_LAYER_NAME'"
		else
			#python3 $MINTCAST_PATH/python/macro_sqlite_curd update tileserverconfig \
			python3 $MINTCAST_PATH/python/macro_postgres_curd update tileserverconfig \
				"layerid='$VECTOR_LAYER_ID', mbtiles='$VECTOR_MBTILES', md5='$VECTOR_LAYER_ID_MD5', layer_name='$COL_LAYER_NAME'" \
				"id=$HAS_LAYER"
			python3 $MINTCAST_PATH/python/macro_tilestache_cache flush '$VECTOR_LAYER_ID_MD5'
		fi
	fi
	echo "LAYER_ID_SUFFIX: $LAYER_ID_SUFFIX"
	echo "VECTOR_LAYER_ID: $VECTOR_LAYER_ID"
	echo "VECTOR_LAYER_ID_MD5: $VECTOR_LAYER_ID_MD5"
	echo "RASTER_LAYER_ID: $RASTER_LAYER_ID"
	echo "RASTER_LAYER_ID_MD5: $RASTER_LAYER_ID_MD5"

	# Check for QML file:
	echo "QML_FILE: $QML_FILE"
	if [[ -z "$QML_FILE" ]]; then
		if [[ -z "$COLOR_TABLE" ]]; then
			COLOR_TABLE="$MINTCAST_PATH/shp/colortable.txt"
		fi
	else
		QML_EXTRACT_PATH="$MINTCAST_PATH/python/macro_extract_colors"
		COLOR_TABLE=$TEMP_DIR/${FILENAME%.*}_color.txt
		echo "COLOR_TABLE: $COLOR_TABLE"
		python3 $QML_EXTRACT_PATH $QML_FILE $COLOR_TABLE #Make colortable
	fi

	# CheckType for Already Byted file and add nodata flag
	NODATAFLAG=''
	POLYGONIZE_FLOAT_FLAG=''
	check_type $INPUT
	# Pre-processing:
	echo "handle_tiff.sh"
	echo "INPUT: $INPUT"
	echo "CLIP_OUT: $CLIP_OUT"
	echo "Clipping..."
	echo "USE_SS_SHAPE: $USE_SS_SHAPE"
	echo "CLIP_BOUNDS: $CLIP_BOUNDS"
	if [[ $DISABLE_CLIP == "NO" ]]; then
		if [[ "$USE_SS_SHAPE" != "NO" ]]; then
			echo "Using SS shapefile..."
			echo "SS_BOUNDARY: $SS_BOUNDARY"
			proc_clip $INPUT $CLIP_OUT $SS_BOUNDARY #Clip to South Sudan boundary
		else
			echo "Not using SS shapefile..."
			#CLIP_OUT=$INPUT
			proc_clip $INPUT $CLIP_OUT
		fi
	else
		CLIP_OUT=$INPUT
	fi
	echo "Projecting..."
	check_projection $CLIP_OUT $PROJ_OUT #Check projection/change to EPSG 3857

	echo "GENERATE_RASTER_TILE: $GENERATE_RASTER_TILE"
	echo "GENERATE_NEW_RES: $GENERATE_NEW_RES"
	echo "GENERATE_VECTOR_TILE $GENERATE_VECTOR_TILE"
	if [[ $GENERATE_RASTER_TILE == "YES" ]]; then
		echo "Generating raster tiles..."
	# Generate raster tiles:
		if [[ "$GENERATE_NEW_RES" == "YES" ]]; then
			# with new res proc
			echo "Setting new resolution..."
			proc_newres $PROJ_OUT $RES_OUT #Set resolution for raster tiles
			echo "Adding colors..."
			echo "COLOR_TABLE: $COLOR_TABLE"
			proc_gdaldem $RES_OUT $COLOR_TABLE $COLOR_OUT
		else
			# without new res proc
			echo "Adding colors..."
			echo "COLOR_TABLE: $COLOR_TABLE"
			proc_gdaldem $PROJ_OUT $COLOR_TABLE $COLOR_OUT
		fi
		# if [[ ! -z "$START_TIME" ]]; then
			if [[ "$GENERATE_NEW_RES" == "YES" ]]; then
				# with new res proc
				MAX_VAL=$(python3 $MINTCAST_PATH/python/macro_gdal max-value $RES_OUT $NETCDF_SINGLE_SUBDATASET)
		    	MIN_VAL=$(python3 $MINTCAST_PATH/python/macro_gdal min-value $RES_OUT $NETCDF_SINGLE_SUBDATASET)
			else
				# use proj out since GENERATE_NEW_RES=no
				MAX_VAL=$(python3 $MINTCAST_PATH/python/macro_gdal max-value $PROJ_OUT $NETCDF_SINGLE_SUBDATASET)
		    	MIN_VAL=$(python3 $MINTCAST_PATH/python/macro_gdal min-value $PROJ_OUT $NETCDF_SINGLE_SUBDATASET)
			fi

			if [[ "$COLORMAP_USE_LOADED" == "YES" ]]; then
	    		# extract from COLOR_TABLE
	    		COL_LEGEND_TYPE=$(python3 $MINTCAST_PATH/python/macro_extract_legend legend-type colormap $MIN_VAL $MAX_VAL $COLOR_TABLE)
		    	if [[ -z "$COL_LEGEND" ]]; then
		    		COL_LEGEND=$(python3 $MINTCAST_PATH/python/macro_extract_legend legend colormap $MIN_VAL $MAX_VAL $COLOR_TABLE)	
		    		COL_COLORMAP=$(python3 $MINTCAST_PATH/python/macro_extract_legend colormap colormap $MIN_VAL $MAX_VAL $COLOR_TABLE)	
		    	else
		    		COL_LEGEND=$COL_LEGEND"|"$(python3 $MINTCAST_PATH/python/macro_extract_legend legend colormap $MIN_VAL $MAX_VAL $COLOR_TABLE)
			    	COL_COLORMAP=$COL_COLORMAP"|"$(python3 $MINTCAST_PATH/python/macro_extract_legend colormap colormap $MIN_VAL $MAX_VAL $COLOR_TABLE)	
		    	fi
	    	else
		    	export COL_LEGEND_TYPE=$(python3 $MINTCAST_PATH/python/macro_extract_legend legend-type noqml $MIN_VAL $MAX_VAL)
		    	if [[ -z "$COL_LEGEND" ]]; then
		    		COL_LEGEND=$(python3 $MINTCAST_PATH/python/macro_extract_legend legend noqml $MIN_VAL $MAX_VAL)	
		    		COL_COLORMAP=$(python3 $MINTCAST_PATH/python/macro_extract_legend colormap noqml $MIN_VAL $MAX_VAL)	
		    	else
		    		COL_LEGEND=$COL_LEGEND"|"$(python3 $MINTCAST_PATH/python/macro_extract_legend legend noqml $MIN_VAL $MAX_VAL)
			    	COL_COLORMAP=$COL_COLORMAP"|"$(python3 $MINTCAST_PATH/python/macro_extract_legend colormap noqml $MIN_VAL $MAX_VAL)	
		    	fi
	    	fi
		# fi
		echo "MIN, MAX, COL_LEGEND: $MIN_VAL, $MAX_VAL, $COL_LEGEND"
		echo "Making raster tiles..."
		proc_tif2mbtiles $COLOR_OUT $RASTER_MBTILES #Make .mbtiles
		echo "Generating zoom levels..."
		proc_gdaladdo $RASTER_MBTILES #Generate zoom levels
		### TO DO: read MBTiles metadata table/store to database
	fi

	VECTOR_SOURCE_LAYER_NAME="$LAYER_NAME"

	if [[ ! -z "$LAYER_INDEX" ]]; then
		VECTOR_SOURCE_LAYER_NAME="$LAYER_NAME""#""$LAYER_INDEX"
	fi

	echo "%%%%%%%% $VECTOR_SOURCE_LAYER_NAME"
	if [[ $GENERATE_VECTOR_TILE == "YES" ]]; then
		# Generate vector tiles:
		echo "Generating polygonized GeoJSON..."
		proc_polygonize $PROJ_OUT $POLY_OUT $VECTOR_SOURCE_LAYER_NAME #Make GeoJSON
		echo "Making vector tiles..."
		proc_geojson2mbtiles $POLY_OUT $VECTOR_MBTILES $VECTOR_SOURCE_LAYER_NAME #Make .mbtiles
	fi
	
	if [[ "$DEV_MODE" != "YES" ]]; then
		if [[ ! -z "$SCP_TO_SERVER" ]]; then
			if [[ $DATASET_TYPE == "tiff" ]]; then
				if [[ -z "$START_TIME" ]]; then
					LAYER_IDS=$(python3 $MINTCAST_PATH/python/macro_string layer_name_to_layer_id $LAYER_NAME$LAYER_ID_SUFFIX '*' '*')
					OUT_DIR="$OUT_DIR/$LAYER_IDS.mbtiles"
				fi
			fi			
		fi
	fi
	if [[ "$MULTIPLE_THREADS_ENABLED" == "YES" ]]; then
		echo "MULTIPLE_THREADS_ENABLED..."
		echo "LAYER_INDEX, index, TOTAL_FILES_COUNT: $LAYER_INDEX, $index, $TOTAL_FILES_COUNT"
		
		sync_file_path=$TEMP_DIR/sync_$index.sh
    	echo "sync_file_path: $sync_file_path"

    	declare -p COL_LEGEND > $sync_file_path
    	declare -p COL_COLORMAP >> $sync_file_path
		if [[ -z "$LAYER_INDEX" ]]; then
			declare -p FIRST_RASTER_LAYER_ID >> $sync_file_path
		fi
		if [[ $TOTAL_FILES_COUNT -eq $((index+1)) ]]; then
			echo "Syncing last..."
			declare -p COL_LEGEND_TYPE >> $sync_file_path
			declare -p RASTER_MBTILES >> $sync_file_path
	    	declare -p VECTOR_MBTILES >> $sync_file_path
	    	declare -p CLIP_OUT >> $sync_file_path
	    	# declare -p OUT_DIR >> $sync_file_path
    	fi
    fi
	#TODO by Libo
	# if [[ $DEV_MODE != 'NO' ]]; then
	# 	# move to OUT_DIR=$TARGET_MBTILES_PATH
	# fi

	# Delete intermediate files:
	#rm $CLIP_OUT $PROJ_OUT $RES_OUT $COLOR_OUT $POLY_OUT

}