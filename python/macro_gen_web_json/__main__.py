#!/usr/bin/env python3

import sys, os
#import sqlite3
import psycopg2
import psycopg2.extras
import json
import ast
import pymongo

MINTCAST_PATH = os.environ.get('MINTCAST_PATH')
config_path = MINTCAST_PATH + "/config/"
sys.path.append(config_path)

RASTER_LAYER_ID_MD5 = os.environ.get('RASTER_LAYER_ID_MD5')
VECTOR_LAYER_ID_MD5 = os.environ.get('VECTOR_LAYER_ID_MD5')

from hashlib import md5

from postgres_config import hostname, username, password, database, MONGODB_CONNECTION

mongo_client = pymongo.MongoClient(MONGODB_CONNECTION) # defaults to port 27017
mongo_db = mongo_client["mintcast"]
mongo_col = mongo_db["layer"]
#DATABASE_PATH = '/sql/database.sqlite'
#hostname = 'localhost'
#username = 'ADV'
#password = 'password'
#database = 'minttestdb'

JSON_FILEPATH = os.environ.get('TARGET_JSON_PATH')

METADATA = {}

def decode(string):
    return bytes(string, "utf-8").decode("unicode_escape")

def getConn():
    #conn = sqlite3.connect(MINTCAST_PATH + DATABASE_PATH)
    conn = psycopg2.connect( host=hostname, user=username, password=password, dbname=database )
    #from postgres_config import conn
    return conn

def getMetadata():
    conn = getConn()
    c = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    try:
        #import pdb; pdb.set_trace()
        c.execute('SELECT * FROM mintcast.metadata')
        for row in c.fetchall():
            METADATA['%s' % row['k']] = row['v']
        # print(METADATA)
    except Exception as e:
        raise e
    finally:
        conn.close()

def updateMetadata():
    # conn = getConn()
    # c = conn.cursor()
    metadataJson = { 'type' : 'mintmap-metadata' }
    metadataJson['server'] = METADATA['server']
    metadataJson['tiles'] = METADATA['tileurl']
    metadataJson['originalDataset'] = METADATA['border_features']
    return metadataJson

def update(identifier):
    conn = getConn()
    c = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    try:
        c.execute("SELECT * FROM mintcast.layer WHERE layerid = '%s'" % identifier)
        for row in c.fetchall():
            toJson(row)
    except Exception as e:
        raise e
    finally:
        conn.close()

def toJson(row):

    layerJson = {}
    if row['type'] == 'raster':
        # TODO
        return


    layerJson['id'] = row['id']

    layerJson['type'] = row['type']
    layerJson['sourceLayer'] = row['sourcelayer']
    layerJson['propertyName'] = 'value'
    layerJson['minzoom'] = row['minzoom']
    layerJson['maxzoom'] = row['maxzoom']
    layerJson['bounds'] = row['bounds'] #not being inserted
    layerJson['originalDatasetCoordinate'] = row['original_dataset_bounds']
    layerJson['values'] = row['valuearray'] #not being inserted
    layerJson['colormap'] = row['colormap']
    layerJson['legend-type'] = row['legend_type']
    layerJson['legend'] = row['legend']

    layerJson['layerName'] = row['name']
    layerJson['layerId'] = row['layerid']
    layerJson['hasData'] = False if row['hasdata'] == 0 else True
    layerJson['hasTimeline'] = False if row['hastimeline'] == 0 else True
    layerJson['md5vector'] = row['md5']
    layerJson['md5raster'] = md5(row['md5'].encode('utf-8')).hexdigest()
    layerJson['dcid'] = row['dcid'].strip()
    layerJson['title'] = row['title']

    if row['hastimeline'] == 1:
        # import pdb; pdb.set_trace()
        step_array = ast.literal_eval(row['step'])
        step_array = [str(i).strip() for i in step_array]
        layerJson['layers'] = {
            'mapping':'', 
            "axis":"slider",
            "stepType":"Time",
            "stepOption":{"type":"string", "format": row['stepoption_format']}, #change this
            "step": step_array
            }

    elif row['hastimeline'] == 0:
        layerJson['layers'] = {
            'mapping':''
            }
    # print(layerJson)
    layerJsonStr = json.dumps(layerJson, indent=4)
    # print(layerJsonStr)
    mongo_metadata = mongo_db["metadata"]

    autoComplete = {'type': 'mintmap-autocomplete'}
    autokey = row['dcid'] if len(layerJson['dcid']) > 1 else row['md5']
    autoComplete[autokey] = row['title']

    ftmp = mongo_metadata.find_one({'type': 'mintmap-autocomplete'})
    if ftmp:
        mongo_metadata.update_one({'type': 'mintmap-autocomplete'}, { '$set': autoComplete })
        # mongo_metadata.replace_one({'type': 'mintmap-autocomplete'}, autoComplete)
    else:
        mongo_metadata.insert_one(autoComplete)

    ftmp = mongo_col.find_one({'md5vector': row['md5']})
    if ftmp:
        # mongo_col.update_one({'md5vector': row['md5']}, { '$set': layerJson })
        mongo_col.replace_one({'md5vector': row['md5']}, layerJson)
    else:
        
        mongo_col.insert_one(layerJson)
    
    try:
        f = open(JSON_FILEPATH + "/%s.json" % row['layerid'],'w')
        f.write(layerJsonStr)
        f.close()
        print(JSON_FILEPATH + "/%s.json" % row['layerid'])    
    except Exception as e:
        print("NOT A BUG: ",e)
    

def updateAll():
    conn = getConn()
    c = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    mongo_db["metadata"].delete_one({'type': 'mintmap-autocomplete'})
    try:
        c.execute('SELECT * FROM mintcast.layer')
        for row in c.fetchall():
            toJson(row)
    except Exception as e:
        raise e
    finally:
        conn.close()
    metadataJson = updateMetadata()
    metaJsonStr = json.dumps(metadataJson, indent=4)

    mongo_metadata = mongo_db["metadata"]
    ftmp = mongo_metadata.find_one({'type': 'mintmap-metadata'})
    if ftmp:
        # mongo_metadata.update_one({'type': 'mintmap-metadata'}, { '$set': metadataJson })
        mongo_metadata.replace_one({'type': 'mintmap-metadata'}, metadataJson )
    else:
        mongo_metadata.insert_one(metadataJson)
    try:
        # print(metaJsonStr)
        f = open(JSON_FILEPATH + "/metadata.json",'w')
        f.write(metaJsonStr)
        f.close()
    except Exception as e:
        print("NOT A BUG: ",e)
    
def updateTileserver():
    pass

def restartTileserver():
    pass

def main():
    method = sys.argv[1]
    getMetadata()
    if method == 'update-all':
        updateAll()
    elif method == 'update':
        identifier = sys.argv[2]
        update(identifier)
    elif method == 'update-config':
        metadataJson = updateMetadata()
        metaJsonStr = json.dumps(metadataJson, indent=4)
        # print(metaJsonStr)
        f = open(JSON_FILEPATH + "/metadata.json",'w')
        f.write(metaJsonStr)
        f.close()
    elif method == 'reload':
        updateTileserver()
        restartTileserver()
usage = '''
USAGE:
    main.py update-all
        update all layers' json and config.json 
        update tileserver's config json
    main.py update identifier 
        update a specific layer
        update all config files
    main.py reload
        update tileserver's config json
        restart tilesever
'''
if __name__ == '__main__':
    if JSON_FILEPATH == None:
        print('Please set up TARGET_JSON_PATH environment variable')
        exit(1)
    num_args = len(sys.argv)
    if num_args < 2:
        print(usage)
        exit(1)
    main()
    mongo_client.close()