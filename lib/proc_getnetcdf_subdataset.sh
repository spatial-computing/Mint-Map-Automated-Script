 #!/usr/bin/env bash

proc_getnetcdf_subdataset(){
    SUBDATASETS_ARRAY=()
    SUBDATASET_LAYERS_ARRAY=()
    NETCDF_FILEPATH=$1

    if [[ -z "$NETCDF_SINGLE_SUBDATASET" ]]; then
        SUBDATASET_STRING="$(gdalinfo $NETCDF_FILEPATH | sed -nE 's/SUBDATASET_.{1,2}_NAME=(.*)/\1/p' | grep -o 'N.*')"  
    else
        pre="s/SUBDATASET_.{1,2}_NAME=(.*"
        suc=")/\1/p"
        SUBDATASET_STRING="$(gdalinfo $NETCDF_FILEPATH | sed -nE $pre$NETCDF_SINGLE_SUBDATASET$suc | grep -o 'N.*')"
    fi
    
    # helper_create_array "SUBDATASETS" "SUBDATASET_STRING" '\n'
    # SUBDATASETS=($(echo "$SUBDATASET_STRING" | awk -F='\n' '{print $1}' ))
    # SUBDATASETS=($(echo "$SUBDATASET_STRING" | tr ' ' '\n' ))
    IFS=$'\n'
    SUBDATASETS=($SUBDATASET_STRING)
    # SUBDATASETS=(`echo $SUBDATASET_STRING`)
    # old=$IFS
    
    for dataset in "${SUBDATASETS[@]}"; do
        IFS=$':'
        name=($dataset)
        if [[ ${name[2]} != 'time_bnds' ]]; then
            echo "gdalwarp -t_srs EPSG:4326 \"$dataset\" \"$MINTCAST_PATH/tmp/$DATASET_NAME.subset.${name[2]}.tif\""
            gdalwarp -t_srs EPSG:4326 "$dataset" "$MINTCAST_PATH/tmp/$DATASET_NAME.subset.${name[2]}.tif"
            # gdalwarp -t_srs EPSG:3857 "$dataset" "$MINTCAST_PATH/tmp/$DATASET_NAME.subset.${name[2]}.tif"
            SUBDATASETS_ARRAY+=("$MINTCAST_PATH/tmp/$DATASET_NAME.subset.${name[2]}.tif")
            SUBDATASET_LAYERS_ARRAY+=(${name[2]})
        fi        
        # gdalwarp -te 22.4 3.4 37.0 23.2 -cutline $MINTCAST_PATH/shp/ss.shp
        # gdal_translate -a_srs EPSG:3857 -tr 0.01 0.01 "$dataset" "$MINTCAST_PATH/tmp/${name[2]}.tif"
        # gdalwarp -te 22.4 3.4 37.0 23.2  -dstnodata 255 -cutline $MINTCAST_PATH/shp/ss.shp 
        # exit 0
    done
}
 