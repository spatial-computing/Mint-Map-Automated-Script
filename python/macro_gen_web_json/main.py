#!/usr/bin/env python3

import sys, os
#import sqlite3
import psycopg2
import json
import ast

MINTCAST_PATH = os.environ.get('MINTCAST_PATH')
config_path = MINTCAST_PATH + "/config/"
sys.path.append(config_path)

RASTER_LAYER_ID_MD5 = os.environ.get('RASTER_LAYER_ID_MD5')
VECTOR_LAYER_ID_MD5 = os.environ.get('VECTOR_LAYER_ID_MD5')

from hashlib import md5

from postgres_config import hostname, username, password, database


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
    c = conn.cursor()
    try:
        #import pdb; pdb.set_trace()
        c.execute('SELECT * FROM mintcast.metadata')
        for row in c.fetchall():
            METADATA['%s' % row[0]] = row[1]
        # print(METADATA)
    except Exception as e:
        raise e
    finally:
        conn.close()

def updateMetadata():
    conn = getConn()
    c = conn.cursor()
    metadataJson = {}
    metadataJson['server'] = METADATA['server']
    metadataJson['tiles'] = METADATA['tileurl']
    metadataJson['originalDataset'] = METADATA['border_features']
    metadataJson['md5raster'] = []
    metadataJson['md5vector'] = []
    metadataJson['layerNames'] = []
    metadataJson['layerIds'] = []
    metadataJson['sourceLayers'] = []
    metadataJson['hasData'] = []
    metadataJson['hasTimeline'] = []
    metadataJson['layers'] = []
    try:
        c.execute('SELECT * FROM mintcast.layer')
        for row in c.fetchall():
            if row[6] == 'raster':
                #metadataJson['md5raster'].append(row[6])
                continue
            print(row)
            metadataJson['layerNames'].append(row[8])
            metadataJson['layerIds'].append(row[1])
            metadataJson['sourceLayers'].append(row[11])
            metadataJson['hasData'].append(False if row[12] == 0 else True)
            metadataJson['hasTimeline'].append(False if row[13] == 0 else True)
            metadataJson['md5vector'].append(row[10])
            metadataJson['md5raster'].append(md5(row[10].encode('utf-8')).hexdigest())
            if row[13] == 1:
                # import pdb; pdb.set_trace()
                step_array = ast.literal_eval(row[-2])
                step_array = [str(i).strip() for i in step_array]
                metadataJson['layers'].append({
                    'id':row[0], 
                    'source-layer': row[11], 
                    'minzoom': row[14], 
                    'maxzoom':row[15], 
                    'type':row[6], 
                    'mapping':'', 
                    "axis":"slider",
                    "stepType":"Time",
                    "stepOption":{"type":"string", "format":"yyyyMM"}, #change this
                    "step": step_array
                    })
            elif row[13] == 0:
                metadataJson['layers'].append({
                    'id':row[0], 
                    'source-layer': row[11], 
                    'minzoom': row[14], 
                    'maxzoom':row[15], 
                    'type':row[6], 
                    'mapping':''
                    })
    except Exception as e:
        raise e
    finally:
        conn.close()
    return metadataJson

def update(identifier):
    conn = getConn()
    c = conn.cursor()
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
    if row[6] == 'raster':
        # TODO
        return

    layerJson['id'] = row[0]
    layerJson['incre'] = row[0]
    layerJson['source-layer'] = row[11]
    layerJson['propertyName'] = 'value'
    layerJson['minzoom'] = row[14]
    layerJson['maxzoom'] = row[15]
    layerJson['bounds'] = row[16] #not being inserted
    layerJson['originalDatasetCoordinate'] = row[32]
    layerJson['values'] = row[29] #not being inserted
    layerJson['colormap'] = row[30]
    layerJson['legend-type'] = row[25]
    layerJson['legend'] = row[26]
    print("####",layerJson)
    print("$$$",row)
    layerJsonStr = json.dumps(layerJson, indent=4)
    # print(layerJsonStr)
    f = open(JSON_FILEPATH + "/%s.json" % row[1],'w')
    f.write(layerJsonStr)
    f.close()
    print(JSON_FILEPATH + "/%s.json" % row[1])

def updateAll():
    conn = getConn()
    c = conn.cursor()
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
    # print(metaJsonStr)
    f = open(JSON_FILEPATH + "/metadata.json",'w')
    f.write(metaJsonStr)
    f.close()

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