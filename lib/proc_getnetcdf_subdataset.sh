 #!/usr/bin/env bash

proc_getnetcdf_subdataset(){
    SUBDATASETS_ARRAY=()
    SUBDATASET_LAYERS_ARRAY=()
    NETCDF_FILEPATH=$1
    HDF5_FLAG="NO"
    NETCDF4_CHECK=$(file $NETCDF_FILEPATH | grep "Hierarchical Data Format (version 5) data")
    
    if [[ -z "$NETCDF4_CHECK" ]]; then

        if [[ -z "$NETCDF_SINGLE_SUBDATASET" ]]; then
            SUBDATASET_STRING="$(gdalinfo $NETCDF_FILEPATH | sed -nE 's/SUBDATASET_.{1,2}_NAME=(.*)/\1/p' | grep -o 'N.*')"  
        else
            pre="s/SUBDATASET_.{1,2}_NAME=(.*"
            suc=")/\1/p"
            SUBDATASET_STRING="$(gdalinfo $NETCDF_FILEPATH | sed -nE $pre$NETCDF_SINGLE_SUBDATASET$suc | grep -o 'N.*')"
        fi
        if [[ -z "$SUBDATASET_STRING" ]]; then
            SUBDATASET_STRING="NETCDF:"$NETCDF_FILEPAT":"$NETCDF_SINGLE_SUBDATASET
        fi  
    else
        pre="s/SUBDATASET_.{1,2}_NAME=(.*"
        suc=")/\1/p"
        SUBDATASET_STRING="$(gdalinfo $NETCDF_FILEPATH | sed -nE $pre$NETCDF_SINGLE_SUBDATASET$suc | grep -o 'N.*')"
        if [[ -z "$SUBDATASET_STRING" ]]; then
            HDF5_FLAG="YES"
            SUBDATASET_STRING="HDF5:\""$NETCDF_FILEPATH"\"://"$NETCDF_SINGLE_SUBDATASET
            # SUBDATASET_STRING="NETCDF:"$NETCDF_FILEPATH":"$NETCDF_SINGLE_SUBDATASET
        fi
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
        NAME_INDEX=2
        if [[ "$HDF5_FLAG" == "YES" ]]; then
            IFS=$'://'
            NAME_INDEX=3
        fi
        name=($dataset)
        if [[ ${name[$NAME_INDEX]} != 'time_bnds' ]]; then
            echo "gdalwarp -t_srs EPSG:4326 \"$dataset\" \"$TEMP_DIR/$DATASET_NAME.subset.${name[$NAME_INDEX]}_$index.tif\""
            # gdalwarp -t_srs EPSG:4326  -to SRC_METHOD=NO_GEOTRANSFORM  "$dataset" "$TEMP_DIR/$DATASET_NAME.subset.${name[2]}_$index.tif"
            gdalwarp -t_srs EPSG:4326 "$dataset" "$TEMP_DIR/$DATASET_NAME.subset.${name[$NAME_INDEX]}_$index.tif"
            # gdalwarp -t_srs EPSG:3857 "$dataset" "$MINTCAST_PATH/tmp/$DATASET_NAME.subset.${name[2]}.tif"
            SUBDATASETS_ARRAY+=("$TEMP_DIR/$DATASET_NAME.subset.${name[$NAME_INDEX]}_$index.tif")
            # SUBDATASETS_ARRAY+=($dataset)
            SUBDATASET_LAYERS_ARRAY+=(${name[$NAME_INDEX]})
        fi        
        # gdalwarp -te 22.4 3.4 37.0 23.2 -cutline $MINTCAST_PATH/shp/ss.shp
        # gdal_translate -a_srs EPSG:3857 -tr 0.01 0.01 "$dataset" "$MINTCAST_PATH/tmp/${name[2]}.tif"
        # gdalwarp -te 22.4 3.4 37.0 23.2  -dstnodata 255 -cutline $MINTCAST_PATH/shp/ss.shp 
        # exit 0
    done
}
 