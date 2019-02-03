#!/usr/bin/env bash

### check_type.sh
# Checks the type of a dataset (Byte, Int16, Float32) and assigns an
# appropriate no data value.
### Inputs: 
# GDAL stats of the desired data file
### Outputs: 
# No data flag
### Procedure:
# - Uses grep on gdalinfo stats to see data type
# - Assigns an appropriate value for the no data flag

check_type () {
    # Make temporary stats file:
    STATS=$1 
    #${1%.*}_stats.tif
    # gdal_translate -stats $1 $STATS

    # Get gdalinfo of stats:
    GDALINFO="$(gdalinfo $STATS)"
    IS_BYTE=$(gdalinfo $STATS | grep 'Type=Byte')
    IS_INT=$(gdalinfo $STATS | grep 'Type=Int')
    IS_FLOAT=$(gdalinfo $STATS | grep 'Type=Float')

    DST_NODATA=$(gdalinfo $STATS | sed -n -e 's/.*missing_value[s]*=\(.*\)/\1/p' | head -1)

    if [[ ! -z "$IS_BYTE" ]]; then
        # mv $STATS $2 # Set temporary stats file as output
        echo "Data is already Byte type"
        if [[ -z $DST_NODATA ]]; then
            NODATAFLAG='-dstnodata 255 '
        else
            NODATAFLAG='-dstnodata $DST_NODATA '
        fi
    elif [[ ! -z "$IS_FLOAT" ]]; then
        if [[ -z $DST_NODATA ]]; then
            NODATAFLAG='-dstnodata -9999 '
        else
            NODATAFLAG='-dstnodata $DST_NODATA '
        fi
        POLYGONIZE_FLOAT_FLAG="-float"
    elif [[ ! -z "$IS_INT" ]]; then
        if [[ -z $DST_NODATA ]]; then
            NODATAFLAG='-dstnodata 32222 '
        else
            NODATAFLAG='-dstnodata $DST_NODATA '
        fi
    else
        if [[ -z $DST_NODATA ]]; then
            NODATAFLAG='-dstnodata -9999 '
        else
            NODATAFLAG='-dstnodata $DST_NODATA '
        fi
        # NODATAFLAG='-dstnodata -9999 '
        #statements
        # Extract min and max values from GDAL info:
        # tmp_min=${GDALINFO#*Minimum=}
        # MIN_VAL=${tmp_min%", Max"*}
        # echo "Minimum value: $MIN_VAL"
        # tmp_max=${GDALINFO#*Maximum=}
        # MAX_VAL=${tmp_max%", M"*}
        # echo "Maximum value: $MAX_VAL"

        # Rescale values and convert data to Byte:

        # no need to convert to byte  by libo
        
        # gdal_translate \
        # -ot Byte \
        # -scale $MIN_VAL $MAX_VAL 0 254 \
        # -a_nodata 255 \
        # $1 \
        # $2

        # Remove temporary stats file:
        # rm $STATS
    fi
}