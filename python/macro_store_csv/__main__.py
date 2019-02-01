import json
import sys
import pymongo
import os
from os.path import expanduser
MINTCAST_PATH = os.environ.get('MINTCAST_PATH')
config_path = MINTCAST_PATH + "/config/"
sys.path.append(config_path)
from postgres_config import hostname, username, password, database, MONGODB_CONNECTION

def store(chartType, layerName, datasetId, csvFile):
    if len(csvFile) == 0:
        return
    if len(csvFile) == 1:
        csvFile = csvFile[0].strip(';').split(';')
    print("Handling csv file for mint-chart...")
    data = {
        "type":chartType, 
        "title": layerName.replace('-_-', ' '), 
        "dataset_id": datasetId, 
        "count": len(csvFile),
        "modified_at": datetime.strftime(datetime.now(), '%Y-%m-%d %H:%M:%S')
    }
    for i in range(len(csvFile)):
        label = "data"
        if i != 0:
            label = "data" + str(i)
        try:
            csvFile[i] = expanduser(csvFile[i])
            with open(csvFile[i], 'r') as file:
                data[label] = file.read()
        except Exception as e:
            raise e
            exit(1)

    mongo_client = pymongo.MongoClient(MONGODB_CONNECTION) # defaults to port 27017
    mongo_db = mongo_client["mintcast"]
    mongo_chart = mongo_db["chart"]
    ftmp = mongo_chart.find_one({'type': chartType, 'dataset_id': datasetId })
    if ftmp:
        mongo_chart.update_one({'type': chartType, 'dataset_id': datasetId }, { '$set': data })
    else:
        mongo_chart.insert_one(data)
    
    mongo_client.close()
    print("Done")


USAGE = '''
python3 macro_store_csv $CHART_TYPE $LAYER_NAME $DATASET_ID $DATAFILE_PATH
'''

if __name__ == '__main__':
    if not MINTCAST_PATH:
        raise Exception('NO MINTCAST_PATH')
        exit(1)
    if len(sys.argv) >= 5:
        store(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:])
    else:
        raise Exception(USAGE.strip())
