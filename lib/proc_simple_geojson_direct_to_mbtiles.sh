#!/usr/bin/env bash

### proc_simple_geojson_direct_to_mbtiles.sh

# Handle direct simple geojson like line and point 
# convert to mbtiles

# Convert GeoJSON to MBTiles:
proc_simple_geojson_direct_to_mbtiles() {
	tippecanoe \
	-f \
	-zg \
	-o $2`#Output filename` \
	--drop-densest-as-needed \
	--extend-zooms-if-still-dropping \
	--layer=$3 `#Layer name`\
	$1 `#Input filename`

	if [[ $? != 0 ]]; then
		echo "tippecanoe failed in proc_simple_geojson_direct_to_mbtiles.sh  Exiting script."
		exit 1
	fi
	# --attribute-type=value:float \
}