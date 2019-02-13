#!/usr/bin/env python3
import click
import json
import sys, os
import pymongo

MINTCAST_PATH = os.environ.get('MINTCAST_PATH')
config_path = MINTCAST_PATH + "/config/"
sys.path.append(config_path)

TEMP_PATH = os.environ.get('TEMP_DIR')
from postgres_config import MONGODB_CONNECTION

SEPARATE_NUMBER = 100
mongo_client = pymongo.MongoClient(MONGODB_CONNECTION) # defaults to port 27017
mongo_db = mongo_client["mintcast"]
mongo_col = mongo_db["geojson_value"]

@click.command()
@click.option('--md5', required=True, type=str)
@click.argument('input_geojson')
@click.argument('output_geojson')
def generalize(md5, input_geojson, output_geojson):
    """Generalize geojson to a certain format used to generate mbtiles"""
    mint_type = None
    shell_communication = ""
    with open(input_geojson, 'r') as file:
        geojson = json.loads(file.read())
        if "mint_properties" in geojson:
            if 'steps' in geojson['mint_properties']:
                shell_communication = "TIME_STEPS='" + json.dumps(geojson['mint_properties']['steps']) + "'"
            
            if geojson['mint_properties']['type'] == 'from-dot-csv':
                mint_type = 'from-dot-csv'
                max_value = str(geojson['mint_properties']['max_value'])
                min_value = str(geojson['mint_properties']['min_value'])
                
                shell_communication += "\nSTART_TIME='%s'" % geojson['mint_properties']['start_time']
                shell_communication += "\nEND_TIME='%s'" % geojson['mint_properties']['end_time']
                shell_communication += "\nCOL_LEGEND_TYPE=linear"
                shell_communication += "\nCOL_LEGEND='[{\"label\":\"%s\", \"value\": %s, \"color\":\"#FCA107\"}, {\"label\":\"%s\", \"value\":%s, \"color\":\"#7F3121\"}]'" % (min_value,min_value,max_value,max_value)
                shell_communication += "\nCOL_COLORMAP='{\"circle-color\": [\"interpolate\",[\"linear\"],[\"get\", \"this_value\"], %s, \"#FCA107\", %s, \"#7F3121\"],\"circle-opacity\": 0.8,\"circle-radius\": [\"interpolate\",[\"linear\"],[\"get\", \"this_value\"], %s, 2, %s, 20]}'" % (min_value, max_value, min_value, max_value)
            del geojson["mint_properties"]
        else:
            shell_communication += "\nCOL_LEGEND_TYPE=none"
            shell_communication += "\nCOL_LEGEND=none"
            shell_communication += "\nCOL_COLORMAP=none"

        max_batch_idx = 0
        max_mint_value_len = 0
        batched_json = {}
        for idx, features in enumerate(geojson['features']):
            if 'properties' in features:
                if 'mint_value' not in features['properties']:
                    mint_value = features['properties']
                    del features['properties']
                    features['properties'] = {'value': mint_value, 'id': idx}
                    mint_type = 'simple-geojson'
                else:
                    mint_value = features['properties']['mint_value']
                    mint_id = features['properties']['mint_id']
                    del features['properties']
                    features['properties'] = {'value': mint_value, 'id': mint_id}
                    if mint_type == 'from-dot-csv':
                        # shell_communication += "MINT_VALUE_LEN=" + str(len(mint_value))
                        # shell_communication += "MINT_VALUE_SEPARATE_NUMBER=" + str(SEPARATE_NUMBER)
                        max_mint_value_len = max(len(mint_value), max_mint_value_len)
                        if len(mint_value) > SEPARATE_NUMBER:
                            features['properties'] = {'value': mint_value[0:SEPARATE_NUMBER], 'id': mint_id}
                            left = mint_value[SEPARATE_NUMBER:]
                            batch_idx = 1
                            for start_i in range(SEPARATE_NUMBER, len(left), SEPARATE_NUMBER):
                                if batch_idx not in batched_json:
                                    batched_json[batch_idx] = {}
                                batched_json[batch_idx][str(mint_id)] = {"value": left[start_i:start_i+SEPARATE_NUMBER]}
                                batch_idx += 1
                            max_batch_idx = max(max_batch_idx, batch_idx)
            geojson['features'][idx] = features
        
        if mint_type == 'from-dot-csv':
            for batch_no, one_batch_json in batched_json.items():
                batch_no_str = md5 + "-" +  str(batch_no)
                ftmp = mongo_col.find_one({'batch_id': batch_no_str})
                if ftmp:
                    mongo_col.replace_one({'batch_id': batch_no_str}, one_batch_json)
                else:
                    one_batch_json['batch_id'] = batch_no_str
                    mongo_col.insert_one(one_batch_json)
        
        # shell_communication += "APPEND_INDEX=" + str(max_batch_idx - 1)
        vector_json = None
        if mint_type == 'from-dot-csv':
            vector_json = {'separate_number': SEPARATE_NUMBER}
            vector_json['batch_index'] = max_batch_idx - 1
            vector_json['mint_value_len'] = max_mint_value_len
            shell_communication += "\nLAYER_TYPE=202"
        elif mint_type == 'simple-geojson':
            shell_communication += "\nLAYER_TYPE=201"

        if vector_json:
            shell_communication += "\nCOL_VECTOR_JSON='%s'" % json.dumps(vector_json)
        else:
            shell_communication += "\nCOL_VECTOR_JSON="
        
        with open(TEMP_PATH + "/geojson_generalized.sh", 'w') as f:
            f.write(shell_communication)

        with open(output_geojson, 'w') as f:
            json.dump(geojson, f)



if __name__ == '__main__':
    generalize()

