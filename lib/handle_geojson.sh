#!/usr/bin/env bash

source $MINTCAST_PATH/lib/proc_simple_geojson_direct_to_mbtiles.sh


handle_geojson() {
	
	VECTOR_MBTILES_DIR=$OUT_DIR/$VECTOR_MD5
	if [[ -d $VECTOR_MBTILES_DIR ]]; then
		rm -rf $VECTOR_MBTILES_DIR
	fi
	mkdir -p $VECTOR_MBTILES_DIR
	VECTOR_LAYER_ID=$(python3 $MINTCAST_PATH/python/macro_string layer_name_to_layer_id $LAYER_NAME vector pbf)
	VECTOR_FILENAME="$VECTOR_LAYER_ID"".mbtiles"
	VECTOR_MBTILES_OUTPUT=$VECTOR_MBTILES_DIR/$VECTOR_FILENAME
	proc_simple_geojson_direct_to_mbtiles $DATAFILE_PATH $VECTOR_MBTILES_OUTPUT $LAYER_NAME

	# insert into tileserver

	# add layer 
	# without raster data
		# fill in the COLs
		# set a no raster flag?
	# Change python code to generate mongo layers
		# add layer_type key
		# we only need vector record in database!
	# Change postgresql layer
		# we only need vector record in database!
		# Add one column layer_type
			# 100 from raster, will have raster and vector data
				# 101 mint-map
				# 102 mint-map-timeseries
			# 200 from simple geojson, load geojson directly from mongodb
				# 201 one simple geojson
					# also could receive a simple shapefile convert to geojson
				# 202 simple geojson timeseries
					# Yijun's dot map
			# 300 from large geojson, load only vector data
				# 301 large geojson convert to vector mbtiles
				# 302 large geojson timeseries
	# for mint-map
		# change mongodb, add layer_type 
		# add load method according different layer_type
	# minty
		# add viz_type
		# add new job

}	