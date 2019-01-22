#!/usr/bin/env python3

import sys, json, os, psycopg2, pymongo

MINTCAST_PATH = os.environ.get('MINTCAST_PATH')
config_path = MINTCAST_PATH + "/config/"
sys.path.append(config_path)

from postgres_config import hostname, username, password, database, MONGODB_CONNECTION

#DATABASE_PATH = '/sql/database.sqlite'
MINTY_SERVER_URL = "http://52.90.74.236:65533"

mongo_client = pymongo.MongoClient(MONGODB_CONNECTION) # defaults to port 27017
mongo_db = mongo_client["mintcast"]
mongo_metadata = mongo_db["metadata"]

def main(base_dir="/data", enable_mongo=True):
    config = {
      "type": "tilestache-config",
      "index": MINTY_SERVER_URL + "/tilestache/index",
      "cache": {
        "name": "Redis",
        "host": "localhost",
        "port": 6379,
        "db": 0,
        "key prefix": "tilestache",
      },
      "layers": {
      }
    }

    #conn = sqlite3.connect(MINTCAST_PATH + DATABASE_PATH)
    #from postgres_config import conn
    conn = psycopg2.connect( host=hostname, user=username, password=password, dbname=database )
    c = conn.cursor()
    try:
        c.execute('SELECT * FROM mintcast.tileserverconfig where layer_name in (select name from mintcast.layer) or layer_name = \'\'')
        for row in c.fetchall():
            if row[1].find('vector_pbf') != -1 :
                config['layers'][row[3]] = {
                      "provider": {
                        "name": "mbtiles", 
                        "tileset": base_dir + row[2].lstrip('.')
                      },
                      "allowed origin": "*",
                      "content encoding": "gzip",
                      "cache lifespan": "604800"
                }
            elif row[1].find('raster_png') != -1:
                config['layers'][row[3]] = {
                      "provider": {
                        "name": "mbtiles", 
                        "tileset": base_dir + row[2].lstrip('.')
                      },
                      "allowed origin": "*",
                      "cache lifespan": "604800"
                }
            
        # jsonStr = json.dumps(config)#, indent=4
        # print(jsonStr)
        if enable_mongo:
            ftmp = mongo_metadata.find_one({'type': 'tilestache-config'})
            if ftmp:
                mongo_metadata.update_one({'type': 'tilestache-config'}, { '$set': config })
            else:
                mongo_metadata.insert_one(config)
        # f = open(MINTCAST_PATH + "/config/tilestache.json",'w')
        # f.write(jsonStr)
        # f.close()
    except Exception as e:
        raise e
    finally:
        conn.close()

usage = '''
USAGE:
    main.py root
    main.py root disable-mongo
'''
if __name__ == '__main__':
    num_args = len(sys.argv)
    if num_args == 2:
        main(sys.argv[1])
    elif num_args == 3:
        main(sys.argv[1], False if sys.argv[1].lower() not in {'no','0','neg'} else True)
    else:
        print(usage)
        exit(1)