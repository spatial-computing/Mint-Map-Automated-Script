#!/usr/bin/env bash

### check_geojson_type.sh

check_geojson_type() {
    GEOJSON_FILE_EXT=$(python3 $MINTCAST_PATH/python/macro_path ext $DATAFILE_PATH)
    if [[ "$GEOJSON_FILE_EXT" == ".csv" ]]; then
        LAYER_TYPE=202
        python3 $MINTCAST_PATH/python/macro_dot_csv_to_geojson $DATAFILE_PATH no_header $TEMP_DIR/$COL_LAYER_NAME.geojson
    else
        if [[ "$GEOJSON" == '.shp' ]]; then
            LAYER_TYPE=201
        else
            LAYER_TYPE=202
        fi
        ogr2ogr -f GeoJSON -t_srs crs:84 $TEMP_DIR/$COL_LAYER_NAME.geojson $DATAFILE_PATH
    fi
    
    GEOJSON_INPUT="$TEMP_DIR/$COL_LAYER_NAME""_generalized.geojson"
    python3 $MINTCAST_PATH/python/macro_generalize_geojson $TEMP_DIR/$COL_LAYER_NAME.geojson $GEOJSON_INPUT

    source $TEMP_DIR/geojson_generalized.sh
    # geojson_filesize_kb=$(du -k "$filename" | cut -f1)
    # if [[ $geojson_filesize_kb -lt 1024 ]]; then
    #     GEOJSON_LAYER_TYPE="simple-geojson"
    # else
    #     GEOJSON_LAYER_TYPE="general-geojson"
    # fi
}