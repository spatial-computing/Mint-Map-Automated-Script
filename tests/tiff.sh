#!/usr/bin/env bash

./bin/mintcast.sh -t tiff -l evap ./tmp/evap_tag.tif


./bin/mintcast.sh -t tiff --with-south-sudan-shp --load-colormap "./shp/bupu_colormap.txt" -l South_Sudan_population_density -m f9a36bd83beacc40fd2089c16996bbb3 --dev-mode-off --tile-server-root "./" --scp-to-default-server --verbose /Users/liber/Downloads/ssudan_pop_density.tif 


--force-restart-tileserver #if needed



# =================
export MINTCAST_PATH=.

./bin/mintcast.sh -t tiff --with-south-sudan-shp --load-colormap "./shp/bupu_colormap.txt" -l South_Sudan_population_density -m "90db5c2f-ab2d-4086-8e07-72edb43545cd" --tile-server-root "./" --disable-new-res --verbose /Users/liber/Downloads/ssudan_pop_density.tif 


# https://s3.amazonaws.com/mint-data-catalog-public-datasets/south_sudan/ssudan_pop_density.tif.zip