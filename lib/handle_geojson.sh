#!/usr/bin/env bash

source $MINTCAST_PATH/lib/proc_simple_geojson_direct_to_mbtiles.sh
source $MINTCAST_PATH/lib/check_geojson_type.sh

handle_geojson() {
    
    # get GEOJSON_INPUT from check_geojson_type
    check_geojson_type
    
    VECTOR_MBTILES_DIR=$OUT_DIR/$VECTOR_MD5
    if [[ -d $VECTOR_MBTILES_DIR ]]; then
        rm -rf $VECTOR_MBTILES_DIR
    fi

    mkdir -p $VECTOR_MBTILES_DIR
    VECTOR_LAYER_ID=$(python3 $MINTCAST_PATH/python/macro_string layer_name_to_layer_id $LAYER_NAME vector pbf)
    VECTOR_FILENAME="$VECTOR_LAYER_ID"".mbtiles"
    VECTOR_MBTILES_OUTPUT=$VECTOR_MBTILES_DIR/$VECTOR_FILENAME

    proc_simple_geojson_direct_to_mbtiles $GEOJSON_INPUT $VECTOR_MBTILES_OUTPUT $LAYER_NAME

    if [[ -z $VECTOR_MD5 ]]; then
        export VECTOR_LAYER_ID_MD5=$(python3 $MINTCAST_PATH/python/macro_md5 $VECTOR_LAYER_ID)
    elif [[ ! -z $VECTOR_MD5 ]]; then
        export VECTOR_LAYER_ID_MD5=$VECTOR_MD5
    fi
    # insert into tileserver
    # no need for simple geojson
    # add layer
    if [[ "$DEV_MODE" != "YES" ]]; then
        HAS_LAYER=$(python3 $MINTCAST_PATH/python/macro_postgres_curd has_tileserver_config $VECTOR_LAYER_ID_MD5)
        if [[ "$HAS_LAYER" = "None" ]]; then
            #python3 $MINTCAST_PATH/python/macro_sqlite_curd insert tileserverconfig \
            python3 $MINTCAST_PATH/python/macro_postgres_curd insert tileserverconfig \
                "layerid, mbtiles, md5, layer_name" \
                "'$VECTOR_LAYER_ID', '$VECTOR_MBTILES_OUTPUT', '$VECTOR_LAYER_ID_MD5', '$COL_LAYER_NAME'"
        else
            #python3 $MINTCAST_PATH/python/macro_sqlite_curd update tileserverconfig \
            python3 $MINTCAST_PATH/python/macro_postgres_curd update tileserverconfig \
                "layerid='$VECTOR_LAYER_ID', mbtiles='$VECTOR_MBTILES_OUTPUT', md5='$VECTOR_LAYER_ID_MD5', layer_name='$COL_LAYER_NAME'" \
                "id=$HAS_LAYER"
            python3 $MINTCAST_PATH/python/macro_tilestache_cache flush '$VECTOR_LAYER_ID_MD5'
        fi
    fi

    # Fill in the vector layer data
    COL_RASTER_OR_VECTOR_TYPE="vector"
    MBTILES_FILEPATH=$VECTOR_MBTILES_OUTPUT
    # without raster data
    #     fill in the COLs
    #     set a no raster flag?

    # Change python code to generate mongo layers
        # add layer_type key
        # we only need vector record in database!

    # Change postgresql layer
        # we only need vector record in database!
        # Add one column layer_type
            # 100 from raster, will have raster and vector data
                # 101 mint-map
                # 102 mint-map-timeseries
            # 200 from simple geojson
                # 201 one simple geojson
                    # also could receive a simple shapefile convert to geojson
                # 202 simple geojson timeseries
                    # Yijun's dot map
                # 203 multiple geojson timeseries 
                    # => convert to 202
                # 201 large geojson convert to vector mbtiles
                # 202 large geojson timeseries
                # 203 multiple geojson timeseries  
                    # will not implement this time
    # for mint-map
        # change mongodb, add layer_type 
        # add load method according different layer_type
    # minty
        # add viz_type
        # add new job

}   