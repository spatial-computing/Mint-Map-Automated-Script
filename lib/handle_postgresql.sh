#!/usr/bin/env bash

# store data to postgresql

handle_postgresql() {

	if [[ ! -z "$LAYER_ID_SUFFIX" ]]; then
		LAYER_ID_SUFFIX=''
	fi
	echo "Handle postgresql"
	#INSERT_LAYER_WITHOUT_DATA=1
	if [[ $INSERT_LAYER_WITHOUT_DATA -eq 1 ]]; then
		echo "Inserting layer without data..."
		COL_LAYER_ID=$(python3 $MINTCAST_PATH/python/macro_string layer_name_to_layer_id $LAYER_NAME$LAYER_ID_SUFFIX vector pbf)
		if [[ -z "$COL_LAYER_NAME" ]]; then
			COL_LAYER_NAME=$(python3 $MINTCAST_PATH/python/macro_string gen_layer_name $LAYER_NAME)
		fi
		COL_MAPPING=''
		#python3 $MINTCAST_PATH/python/sqlite3_curd insert layer \
		python3 $MINTCAST_PATH/python/macro_postgres_curd insert layer \
			"layerid, type, tileformat, name, stdname, md5, sourceLayer, original_id" \
			"'$COL_LAYER_ID', 'vector', 'pbf', '$COL_LAYER_NAME', '', '', '', 0 " #, 0, 0, 0, 0, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '$COL_MAPPING', '', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP"
		exit 0
	fi
	COL_RASTER_OR_VECTOR_TYPE=$COL_RASTER_OR_VECTOR_TYPE

	COL_MD5=$FIRST_RASTER_LAYER_ID
	COL_TILE_FORMAT='png'
	if [[ $COL_RASTER_OR_VECTOR_TYPE = 'vector' ]]; then
		COL_TILE_FORMAT='pbf'
		# COL_MD5=$VECTOR_LAYER_ID_MD5
		COL_MD5=$VECTOR_MD5
	fi
	echo "COL_MD5: $COL_MD5"
	# echo "$MINTCAST_PATH/python/macro_string layer_name_to_layer_id $LAYER_NAME$LAYER_ID_SUFFIX $COL_RASTER_OR_VECTOR_TYPE $COL_TILE_FORMAT"
	COL_LAYER_ID=$(python3 $MINTCAST_PATH/python/macro_string layer_name_to_layer_id "$LAYER_NAME$LAYER_ID_SUFFIX" $COL_RASTER_OR_VECTOR_TYPE $COL_TILE_FORMAT)
	echo "COL_LAYER_ID: $COL_LAYER_ID"
	# This layer name is not the layer name we are using.
	# Source Layer is the actual layer name
	if [[ -z "$COL_LAYER_NAME" ]]; then
		COL_LAYER_NAME=$(python3 $MINTCAST_PATH/python/macro_string gen_layer_name $LAYER_NAME)
	fi
	#echo "COL_LAYER_NAME: $COL_LAYER_NAME"
	COL_SOURCE_LAYER=$LAYER_NAME
	COL_ORIGINAL_ID=0
	COL_HAS_DATA=1
	
	COL_START_TIME=$START_TIME
	COL_END_TIME=$END_TIME

	COL_AXIS=''
	COL_STEP_TYPE=''
	COL_STEP_OPTION_TYPE=''
	COL_STEP_OPTION_FORMAT=''
	COL_STEP=''
	PSQL_TO_DATE=''
	TIME_FORMAT=''

	if [[ -z "$TIME_STEPS" ]]; then
		TIME_STEPS='[]'
	fi
 

	if [[ ! -z "$START_TIME" ]]; then
		PSQL_TO_DATE=$(python3 $MINTCAST_PATH/python/macro_postgres_curd to_date $DATATIME_FORMAT)
		TIME_FORMAT="$PSQL_TO_DATE"
		COL_AXIS="slider"
		COL_STEP_TYPE="Time"
		COL_STEP_OPTION_TYPE="string"
		COL_STEP_OPTION_FORMAT="$TIME_FORMAT"
		COL_STEP="$TIME_STEPS"
	fi

	if [[ -z "$COL_STEP" ]]; then
		COL_STEP='[]'
	fi

	echo "COL_STEP: $COL_STEP"

	COL_SERVER=''
	COL_TILE_URL=''
	COL_STYLE_TYPE='fill'
	COL_MAPPING=''

	CURRENT_TIMESTAMP=$(date +%Y%m%d-%H:%M:%S)

	COL_MBTILES_FILENAME=$(python3 $MINTCAST_PATH/python/macro_path basename $MBTILES_FILEPATH)
	COL_BOUNDS=$(python3 $MINTCAST_PATH/python/macro_mbtiles bounds $MBTILES_FILEPATH)
	echo "COL_BOUNDS: $COL_BOUNDS"
	COL_MAXZOOM=$(python3 $MINTCAST_PATH/python/macro_mbtiles maxzoom $MBTILES_FILEPATH)
	COL_MINZOOM=$(python3 $MINTCAST_PATH/python/macro_mbtiles minzoom $MBTILES_FILEPATH)
	COL_VALUE_ARRAY=''
	COL_VECTOR_JSON=''
	if [[ $COL_RASTER_OR_VECTOR_TYPE = 'vector' ]]; then
		COL_VALUE_ARRAY=$(python3 $MINTCAST_PATH/python/macro_mbtiles values $MBTILES_FILEPATH)
		COL_VECTOR_JSON=$(python3 $MINTCAST_PATH/python/macro_mbtiles vector_json $MBTILES_FILEPATH)
	fi
	echo "COL_VALUE_ARRAY: $COL_VALUE_ARRAY"
	

	# TODO
	COL_HAS_TIMELINE=1
	COL_DIRECTORY_FORMAT=$OUTPUT_DIR_STRUCTURE_FOR_TIMESERIES
	echo "COL_DIRECTORY_FORMAT: $COL_DIRECTORY_FORMAT"
	
	COL_DIRECTORY_FORMAT=''
	if [[ -z "$START_TIME" ]]; then
		COL_HAS_TIMELINE=0
	fi

	if [[ ! -z "$START_TIME" ]]; then
		COL_HAS_TIMELINE=1
	fi

	COL_JSON_FILENAME="$COL_LAYER_ID.json"
	if [[ -z "$MAX_VAL" ]]; then
		if [[ -z "$QML_FILE" ]]; then
			# ------TODO-------Apply to different occassion like: netcdf??or only tiff
			# MAX_VAL=$(python3 $MINTCAST_PATH/python/macro_gdal max-value $DATAFILE_PATH)
			# MIN_VAL=$(python3 $MINTCAST_PATH/python/macro_gdal min-value $DATAFILE_PATH)
			MAX_VAL=$(python3 $MINTCAST_PATH/python/macro_gdal max-value $CLIP_OUT $NETCDF_SINGLE_SUBDATASET)
			MIN_VAL=$(python3 $MINTCAST_PATH/python/macro_gdal min-value $CLIP_OUT $NETCDF_SINGLE_SUBDATASET)
			COL_LEGEND_TYPE=$(python3 $MINTCAST_PATH/python/macro_extract_legend legend-type noqml $MIN_VAL $MAX_VAL)
			COL_LEGEND=$(python3 $MINTCAST_PATH/python/macro_extract_legend legend noqml $MIN_VAL $MAX_VAL)
			COL_COLORMAP=$(python3 $MINTCAST_PATH/python/macro_extract_legend colormap noqml $MIN_VAL $MAX_VAL)		
		else
			COL_LEGEND_TYPE=$(python3 $MINTCAST_PATH/python/macro_extract_legend legend-type $QML_FILE)
			COL_LEGEND=$(python3 $MINTCAST_PATH/python/macro_extract_legend legend $QML_FILE)
			COL_COLORMAP=$(python3 $MINTCAST_PATH/python/macro_extract_legend colormap $QML_FILE)
		fi
	fi
	COL_ORIGINAL_DATASET_BOUNDS=$(python3 $MINTCAST_PATH/python/macro_gdal bounds-geojson-format $DATAFILE_PATH)

	# HAS_LAYER=$(python3 $MINTCAST_PATH/python/macro_sqlite_curd has_layer $COL_LAYER_ID)
	HAS_LAYER=$(python3 $MINTCAST_PATH/python/macro_postgres_curd has_layer $COL_MD5)	
	# echo "null, '$COL_LAYER_ID', '$COL_RASTER_OR_VECTOR_TYPE', '$COL_TILE_FORMAT', '$COL_LAYER_NAME', '$COL_SOURCE_LAYER', $COL_ORIGINAL_ID, $COL_HAS_DATA, $COL_HAS_TIMELINE, $COL_MAXZOOM, $COL_MINZOOM, '$COL_BOUNDS', '$COL_MBTILES_FILENAME', '$COL_DIRECTORY_FORMAT', '$COL_START_TIME', '$COL_END_TIME', '$COL_JSON_FILENAME', '$COL_SERVER', '$COL_TILE_URL', '$COL_STYLE_TYPE', '$COL_LEGEND_TYPE', '$COL_LEGEND', '$COL_VALUE_ARRAY', '$COL_VECTOR_JSON', '$COL_COLORMAP', '$COL_ORIGINAL_DATASET_BOUNDS', '$COL_MAPPING', '$COL_CKAN_URL', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP"

	if [[ "$HAS_LAYER" = "None" ]]; then
		echo "DOES NOT HAVE LAYER"
		echo "COL_LAYER_ID: $COL_LAYER_ID"
		if [[ -z "$START_TIME" && $DATASET_TYPE != "tiff-time" ]]; then
			python3 $MINTCAST_PATH/python/macro_postgres_curd insert layer \
				"layerid, type, tileformat, name, sourceLayer, hasData, hasTimeline, bounds, mbfilename, directory_format, json_filename, server, tileurl, legend_type, legend, valueArray, vector_json, colormap, original_dataset_bounds, mapping, stdname, md5, original_id , minzoom, maxzoom"\
				"'$COL_LAYER_ID', '$COL_RASTER_OR_VECTOR_TYPE', '$COL_TILE_FORMAT', '$COL_LAYER_NAME', '$COL_SOURCE_LAYER', $COL_HAS_DATA, $COL_HAS_TIMELINE, '$COL_BOUNDS', '$COL_MBTILES_FILENAME', '$COL_DIRECTORY_FORMAT', '$COL_JSON_FILENAME', '$COL_SERVER','$COL_TILE_URL', '$COL_LEGEND_TYPE', '$COL_LEGEND', '$COL_VALUE_ARRAY', '$COL_VECTOR_JSON', '$COL_COLORMAP', '$COL_ORIGINAL_DATASET_BOUNDS', '$COL_MAPPING', '', '$COL_MD5', $COL_ORIGINAL_ID, $COL_MINZOOM, $COL_MAXZOOM"
		elif [[ $DATASET_TYPE == "tiff-time" ]]; then
 			echo "python3 $MINTCAST_PATH/python/macro_postgres_curd insert layer layerid, type, tileformat, name, sourceLayer, hasData, hasTimeline, bounds, mbfilename, directory_format, json_filename, server, tileurl, legend_type, legend, valueArray, vector_json, colormap, original_dataset_bounds, mapping, stdname, md5, original_id , minzoom, maxzoom, axis, stepType, stepOption_type, stepOption_format, step '$COL_LAYER_ID', '$COL_RASTER_OR_VECTOR_TYPE', '$COL_TILE_FORMAT', '$COL_LAYER_NAME', '$COL_SOURCE_LAYER', $COL_HAS_DATA, $COL_HAS_TIMELINE, '$COL_BOUNDS', '$COL_MBTILES_FILENAME', '$COL_DIRECTORY_FORMAT', '$COL_JSON_FILENAME', '$COL_SERVER','$COL_TILE_URL', '$COL_LEGEND_TYPE', '$COL_LEGEND', '$COL_VALUE_ARRAY', '$COL_VECTOR_JSON', '$COL_COLORMAP', '$COL_ORIGINAL_DATASET_BOUNDS', '$COL_MAPPING', '', '$COL_MD5', $COL_ORIGINAL_ID, $COL_MINZOOM, $COL_MAXZOOM, '$COL_AXIS', '$COL_STEP_TYPE', '$COL_STEP_OPTION_TYPE', '$COL_STEP_OPTION_FORMAT', '$COL_STEP'"
			python3 $MINTCAST_PATH/python/macro_postgres_curd insert layer \
				"layerid, type, tileformat, name, sourceLayer, hasData, hasTimeline, bounds, mbfilename, directory_format, json_filename, server, tileurl, legend_type, legend, valueArray, vector_json, colormap, original_dataset_bounds, mapping, stdname, md5, original_id , minzoom, maxzoom, axis, stepType, stepOption_type, stepOption_format, step"\
				"'$COL_LAYER_ID', '$COL_RASTER_OR_VECTOR_TYPE', '$COL_TILE_FORMAT', '$COL_LAYER_NAME', '$COL_SOURCE_LAYER', $COL_HAS_DATA, $COL_HAS_TIMELINE, '$COL_BOUNDS', '$COL_MBTILES_FILENAME', '$COL_DIRECTORY_FORMAT', '$COL_JSON_FILENAME', '$COL_SERVER','$COL_TILE_URL', '$COL_LEGEND_TYPE', '$COL_LEGEND', '$COL_VALUE_ARRAY', '$COL_VECTOR_JSON', '$COL_COLORMAP', '$COL_ORIGINAL_DATASET_BOUNDS', '$COL_MAPPING', '', '$COL_MD5', $COL_ORIGINAL_ID, $COL_MINZOOM, $COL_MAXZOOM, '$COL_AXIS', '$COL_STEP_TYPE', '$COL_STEP_OPTION_TYPE', '$COL_STEP_OPTION_FORMAT', '$COL_STEP'"
		elif [[ ! -z "$START_TIME" ]]; then
			python3 $MINTCAST_PATH/python/macro_postgres_curd insert layer \
				"layerid, type, tileformat, name, sourceLayer, hasData, hasTimeline, mbfilename, directory_format, json_filename, server, tileurl, legend_type, legend, valueArray, vector_json, colormap, original_dataset_bounds, mapping, stdname, md5, original_id, minzoom, maxzoom, bounds, starttime, endtime, axis, stepType, stepOption_type, stepOption_format, step"\
				"'$COL_LAYER_ID', '$COL_RASTER_OR_VECTOR_TYPE', '$COL_TILE_FORMAT', '$COL_LAYER_NAME', '$COL_SOURCE_LAYER', $COL_HAS_DATA, $COL_HAS_TIMELINE, '$COL_MBTILES_FILENAME', '$COL_DIRECTORY_FORMAT', '$COL_JSON_FILENAME', '$COL_SERVER','$COL_TILE_URL', '$COL_LEGEND_TYPE', '$COL_LEGEND', '$COL_VALUE_ARRAY', '$COL_VECTOR_JSON', '$COL_COLORMAP', '$COL_ORIGINAL_DATASET_BOUNDS', '$COL_MAPPING', '', '$COL_MD5', $COL_ORIGINAL_ID, $COL_MINZOOM, $COL_MAXZOOM, '$COL_BOUNDS', to_date('$COL_START_TIME', '$PSQL_TO_DATE'), to_date('$COL_END_TIME','$PSQL_TO_DATE'), '$COL_AXIS', '$COL_STEP_TYPE', '$COL_STEP_OPTION_TYPE', '$COL_STEP_OPTION_FORMAT', '$COL_STEP'"

		fi
	else
		echo "HAS LAYER"
		if [[ -z $START_TIME ]]; then
			python3 $MINTCAST_PATH/python/macro_postgres_curd update layer \
				"layerid='$COL_LAYER_ID', type='$COL_RASTER_OR_VECTOR_TYPE', tileformat='$COL_TILE_FORMAT', name='$COL_LAYER_NAME', sourceLayer='$COL_SOURCE_LAYER', original_id=$COL_ORIGINAL_ID, hasData=$COL_HAS_DATA, hasTimeline=$COL_HAS_TIMELINE, bounds='$COL_BOUNDS', mbfilename='$COL_MBTILES_FILENAME', directory_format='$COL_DIRECTORY_FORMAT', starttime=Null, endtime=Null, json_filename='$COL_JSON_FILENAME', server='$COL_SERVER', tileurl='$COL_TILE_URL', styleType='$COL_STYLE_TYPE', legend_type='$COL_LEGEND_TYPE', legend='$COL_LEGEND', valueArray='$COL_VALUE_ARRAY', vector_json='$COL_VECTOR_JSON', colormap='$COL_COLORMAP', original_dataset_bounds='$COL_ORIGINAL_DATASET_BOUNDS', mapping='$COL_MAPPING', create_at=CURRENT_TIMESTAMP, modified_at=CURRENT_TIMESTAMP, minzoom=$COL_MINZOOM, maxzoom=$COL_MAXZOOM, md5='$COL_MD5'" \
				"id=$HAS_LAYER"
		elif [[ $DATASET_TYPE == "tiff-time" ]]; then
			python3 $MINTCAST_PATH/python/macro_postgres_curd update layer \
				"layerid='$COL_LAYER_ID', type='$COL_RASTER_OR_VECTOR_TYPE', tileformat='$COL_TILE_FORMAT', name='$COL_LAYER_NAME', sourceLayer='$COL_SOURCE_LAYER', original_id=$COL_ORIGINAL_ID, hasData=$COL_HAS_DATA, hasTimeline=$COL_HAS_TIMELINE, bounds='$COL_BOUNDS', mbfilename='$COL_MBTILES_FILENAME', directory_format='$COL_DIRECTORY_FORMAT', starttime=Null, endtime=Null, json_filename='$COL_JSON_FILENAME', server='$COL_SERVER', tileurl='$COL_TILE_URL', styleType='$COL_STYLE_TYPE', legend_type='$COL_LEGEND_TYPE', legend='$COL_LEGEND', valueArray='$COL_VALUE_ARRAY', vector_json='$COL_VECTOR_JSON', colormap='$COL_COLORMAP', original_dataset_bounds='$COL_ORIGINAL_DATASET_BOUNDS', mapping='$COL_MAPPING', create_at=CURRENT_TIMESTAMP, modified_at=CURRENT_TIMESTAMP, minzoom=$COL_MINZOOM, maxzoom=$COL_MAXZOOM, md5='$COL_MD5', axis='$COL_AXIS', stepType='$COL_STEP_TYPE', stepOption_type='$COL_STEP_OPTION_TYPE', stepOption_format='$COL_STEP_OPTION_FORMAT', step='$COL_STEP'" \
				"id=$HAS_LAYER"
		elif [[ ! -z $START_TIME ]]; then
			python3 $MINTCAST_PATH/python/macro_postgres_curd update layer \
				"layerid='$COL_LAYER_ID', type='$COL_RASTER_OR_VECTOR_TYPE', tileformat='$COL_TILE_FORMAT', name='$COL_LAYER_NAME', sourceLayer='$COL_SOURCE_LAYER', original_id=$COL_ORIGINAL_ID, hasData=$COL_HAS_DATA, hasTimeline=$COL_HAS_TIMELINE, bounds='$COL_BOUNDS', mbfilename='$COL_MBTILES_FILENAME', directory_format='$COL_DIRECTORY_FORMAT', starttime=to_date('$COL_START_TIME', '$PSQL_TO_DATE'), endtime=to_date('$COL_END_TIME', '$PSQL_TO_DATE'), json_filename='$COL_JSON_FILENAME', server='$COL_SERVER', tileurl='$COL_TILE_URL', styleType='$COL_STYLE_TYPE', legend_type='$COL_LEGEND_TYPE', legend='$COL_LEGEND', valueArray='$COL_VALUE_ARRAY', vector_json='$COL_VECTOR_JSON', colormap='$COL_COLORMAP', original_dataset_bounds='$COL_ORIGINAL_DATASET_BOUNDS', mapping='$COL_MAPPING', create_at=CURRENT_TIMESTAMP, modified_at=CURRENT_TIMESTAMP, minzoom=$COL_MINZOOM, maxzoom=$COL_MAXZOOM, md5='$COL_MD5', axis='$COL_AXIS', stepType='$COL_STEP_TYPE', stepOption_type='$COL_STEP_OPTION_TYPE', stepOption_format='$COL_STEP_OPTION_FORMAT', step='$COL_STEP'" \
				"id=$HAS_LAYER"
		fi

	fi
}