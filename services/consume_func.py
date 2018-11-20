# # Parse response, according to type, download from ISI,   make MBTiles, store to postgres,

import wget
import subprocess
import sys, os
from datetime import datetime

#MINTCAST_PATH = os.environ.get('MINTCAST_PATH')
MINTCAST_path = '/Users/ADV/Mint-Map-Automated-Script'

#def export_metadata(self, parsed):
#       python3 $MINTCAST_PATH/python/macro_postgres_curd/main.py insert tileserverconfig \
#       "layerid, mbtiles, md5" \
#       "'$VECTOR_LAYER_ID', '$VECTOR_MBTILES', '$VECTOR_LAYER_ID_MD5'"

def download_data(url, out_dir):
    try:
        wget.download(url, out=out_dir)
        print("URL: " + url)
        filename = url.split('/')[-1] # Made need to change this later to account for specific directory structures
        print("FILENAME: " + filename)
        if out_dir[-1] != '/':
            out_dir += '/'
        dl_path = out_dir + filename
        return([True, dl_path])
    except Exception as e:
        print(e)
        return([False, "Null"])

def run_mintcast(sh_command):
    try:
        subprocess.call(sh_command, shell=True)
        return(True)
    except Exception as e:
        print(e)
        return(False)

def parse_message(msg):
    # all of this probably needs to be changed once we get the real resp format
    dv = msg['dataset_file']
    #json_meta = resp['dataset']['json_metadata']
    parsed = {}
    parsed['uri'] = dv['uri']
    parsed['data_type'] = dv['uri'].split('.')[-1]
    parsed['temporal_coverage'] = dv['temporal_coverage']
    parsed['time_format'] = "YYYYMMDD"
    parsed['layer_name'] = [name for name in dv['temporal_coverage'].keys()]
    st = [dv['temporal_coverage'][key]['start_time'] for key in dv['temporal_coverage'].keys()]
    et = [dv['temporal_coverage'][key]['end_time'] for key in dv['temporal_coverage'].keys()]
    startp = datetime.strptime(st[0], "%Y-%m-%dT%H:%M:%S")
    startf = startp.strftime("%Y%m%d")
    endp = datetime.strptime(et[0], "%Y-%m-%dT%H:%M:%S")
    endf = endp.strftime("%Y%m%d")
    if startf == endf: 
        parsed['time_stamp'] = startf
    else:
        print("&&&&&&& START TIME AND END TIME MISMATCH &&&&&&&")
        parsed['time_stamp'] = startf
    return(parsed)

#event_type: {registration, update, delete), timestamp: just one date, dataset_id: , dataset: json that includes id, name, description, owner id, and another json w/ metadata (maybe contain uri), 
def consume_func(resp, out_dir):
    messages = resp['messages']
    offset = resp['offset']
    for message in messages:
        par = parse_message(message)
        dtype = parsed['data_type']
        acceptable_types = ['tif', 'nc', 'asc']
        #out_dir = '/Users/ADV/Mint-Map-Automated-Script/dist/' # CHANGE/REMOVE THIS
        if dtype in acceptable_types:
            [dl_success, dl_path] = download_data(par['uri'], out_dir)
            if dl_success:
                MINTCAST_command = MINTCAST_PATH + "/bin/mintcast.sh"
                MINTCAST_command += " --time-format " + par['time_format']
                MINTCAST_command += " --time-stamp " + par['time_stamp']
                MINTCAST_command += " --disable-clip"
                #MINTCAST_command += " -m " + par['md5']
                if dtype == 'nc':
                    #MINTCAST_command += ""
                    netcdf_time = False #something to detect netCDF time series
                    netcdf_single = True #something to detect single netCDF
                    if netcdf_single:
                        MINTCAST_command += " -t single-netcdf"
                    elif netcdf_time:
                        #get time info
                        MINTCAST_command += " -t netcdf"
                    MINTCAST_command += " " + dl_path
                elif dtype == 'tif':
                    tiled_tif = False #something to detect tiled tiff
                    tif_time = False #something to detect tif time series
                    if tiled_tif:
                        # get tile info
                        MINTCAST_command += " -t tiled"
                    elif tif_time:
                        # get time info
                        MINTCAST_command += " -t tiff-time"
                    else:
                        MINTCAST_command += " -t tiff"
                    MINTCAST_command += " " + dl_path
                elif dtype == 'asc':
                    MINTCAST_command = "python3 " + MINTCAST_PATH + "/bin/mintcast_extime.py " + dl_path
                    #asc_time = #something to detect ASC time series
                    #if asc_time:
                    #   MINTCAST_command 
                    #asc_single = #something to detect single ASC
                #Run MINTCAST
                mintcheck = run_mintcast(MINTCAST_command)
                if mintcheck:
                    print("MINTCAST success - MBTiles generated and metadata stored in Postgres")
                    # send success message
                else:
                    print("MINTCAST failure - could not generate MBTiles. metadata not stored in Postgres")
                    # send MINTCAST failed message

            else:
                    print("Could not download requested data file.  Will try again later.")
                    #send Could not DL message - will do later
        else:
            # send invalid data format
            print("Could not fulfill request- invalid data type")
    
    # Save offset to text file
    services_path = MINTCAST_path + "/services/"
    with open("offset.txt", w) as od:
        od.write(str(offset))
        od.close()


