#!/usr/bin/env python3
import click
import json
import sys, os
import pymongo
from postgres_config import MONGODB_CONNECTION

SEPARATE_NUMBER = 365
mongo_client = pymongo.MongoClient(MONGODB_CONNECTION) # defaults to port 27017
mongo_db = mongo_client["mintcast"]
mongo_col = mongo_db["geojson_value"]

@click.command()
@click.option('--layer', required=True, type=str)
@click.argument('input_geojson')
@click.argument('output_geojson')
def generalize(layer, input_geojson, output_geojson):
    """Generalize geojson to a certain format used to generate mbtiles"""
    mint_type = None
    with open(input_geojson, 'r') as file:
        geojson = json.loads(file.read())
        if "mint_properties" in geojson:
            if 'steps' in geojson['mint_properties']:
                os.environ["TIME_STEPS"] = geojson['mint_properties']['steps']
            
            if geojson['mint_properties']['type'] == 'from-dot-csv':
                mint_type = 'from-dot-csv'
                max_value = geojson['mint_properties']['max_value']
                min_value = geojson['mint_properties']['min_value']
                os.environ["COL_LEGEND_TYPE"] = 'linear'
                os.environ["COL_LEGEND"] = "[{\"label\":\"%s\", \"value\": %s, \"color\":\"#FCA107\"}, {\"label\":\"%s\", \"value\":%s, \"color\":\"#7F3121\"}]" % (min_value,min_value,max_value,max_value)
                os.environ["COL_COLORMAP"] = "{\"circle-color\": [\"interpolate\",[\"linear\"],[\"get\", \"this_value\"], %s, \"#FCA107\", %s, \"#7F3121\"],\"circle-opacity\": 0.8,\"circle-radius\": [\"interpolate\",[\"linear\"],[\"get\", \"this_value\"], %s, 2, %s, 20]}" % (min_value, max_value, min_value, max_value)
            del geojson["mint_properties"]
        else:
            os.environ["COL_LEGEND_TYPE"] = "none"
            os.environ["COL_LEGEND"] = "none"
            os.environ["COL_COLORMAP"] = "none"

        for idx, features in enumerate(geojson['features']):
            if 'properties' in features:
                if 'mint_value' not in features['properties']:
                    mint_value = features['properties']
                    del features['properties']
                    features['properties'] = {'value': mint_value, 'id': idx}
                else:
                    mint_value = features['properties']['mint_value']
                    mint_id = features['properties']['mint_id']
                    del features['properties']
                    features['properties'] = {'value': mint_value, 'id': mint_id}
                    if mint_type == 'from-dot-csv':
                        os.environ["MINT_VALUE_LEN"] = len(mint_value)
                        os.environ["MINT_VALUE_SEPARATE_NUMBER"] = SEPARATE_NUMBER
                        if len(mint_value) > SEPARATE_NUMBER:
                            features['properties'] = {'value': mint_value[0:SEPARATE_NUMBER], 'id': mint_id}
                            left = mint_value[SEPARATE_NUMBER:]
                            append_idx = 1
                            for start_i in range(SEPARATE_NUMBER, len(left), SEPARATE_NUMBER):
                                append_j = {"append_idx": append_idx_str, "value": left[start_i:start_i+SEPARATE_NUMBER]}
                                append_idx_str = layer + str(append_idx)
                                ftmp = mongo_col.find_one({'append_idx': append_idx_str})
                                if ftmp:
                                    mongo_col.replace_one({'append_idx': append_idx_str}, append_j)
                                else:                                    
                                    mongo_col.insert_one(append_j)

            geojson['features'][idx] = features

        with open(output_geojson, 'w') as f:
            json.dump(geojson, f)
            


if __name__ == '__main__':
    generalize()

