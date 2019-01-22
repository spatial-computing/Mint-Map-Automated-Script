#!/usr/bin/env python3

import sys, json, os, psycopg2
import psycopg2.extras
MINTCAST_PATH = os.environ.get('MINTCAST_PATH')
config_path = MINTCAST_PATH + "/config/"
sys.path.append(config_path)

from postgres_config import hostname, username, password, database

#DATABASE_PATH = '/sql/database.sqlite'

def main(root = '../', port='80', server='0.0.0.0'):
    config = {'options': {'paths': {'root': root, 'mbtiles': ''}, 'domains': ['%s:%s'%(server, port),'localhost:%s'%port, '127.0.0.1:%s'%port, '52.90.74.236:65533'], 'formatQuality': {'png': 100, 'jpeg': 80, 'webp': 90}, 'maxScaleFactor': 3, 'maxSize': 2048, 'pbfAlias': 'pbf', 'serveAllFonts': False, 'serveStaticMaps': False}, 'data': {}}
    #conn = sqlite3.connect(MINTCAST_PATH + DATABASE_PATH)
    #from postgres_config import conn
    conn = psycopg2.connect( host=hostname, user=username, password=password, dbname=database )
    c = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    try:
        c.execute('SELECT * FROM mintcast.tileserverconfig where layer_name in (select name from mintcast.layer) or layer_name = \'\'')
        for row in c.fetchall():
            config['data'][row['md5']] = {'mbtiles':row['mbtiles']}
        jsonStr = json.dumps(config, indent=4)
        # print(layerJsonStr)
        f = open(MINTCAST_PATH + "/config/config.json",'w')
        f.write(jsonStr)
        f.close()
    except Exception as e:
        raise e
    finally:
        conn.close()

usage = '''
USAGE:
    main.py root port
    main.py root port server
'''
if __name__ == '__main__':
    num_args = len(sys.argv)
    if num_args == 3:
        server = '0.0.0.0'
        main(sys.argv[1], sys.argv[2])
    elif num_args == 4:
        main(sys.argv[1], sys.argv[2], sys.argv[3])
    else:
        print(usage)
        exit(1)