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

	

}	