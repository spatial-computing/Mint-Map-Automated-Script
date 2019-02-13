#!/usr/bin/env python3

import sys
import csv
import json


USAGE = """python3 ./python/macro_dot_csv_to_geojson csv_filepath output_dir"""


def main(csv_file, contain_header, output_file):
    data, times, values = read_csv(csv_file, contain_header)
    sorted_time = sorted(times)
    geojson = generate_point_geojson(data, sorted_time, values)

    with open(output_file, 'w') as f:
        json.dump(geojson, f)
    print("Dot CSV has been converted to GeoJSON.")


def generate_point_geojson(data, times, values):
    geojson = {}
    geojson['type'] = 'FeatureCollection'
    geojson['crs'] = { "type": "name", "properties": { "name": "urn:ogc:def:crs:OGC:1.3:CRS84" } }
    geojson['mint_properties'] = {}
    geojson['mint_properties']['type'] = 'from-dot-csv'
    geojson['mint_properties']['steps'] = times
    geojson['mint_properties']['max_value'] = max(values)
    geojson['mint_properties']['min_value'] = min(values)
    geojson['mint_properties']['start_time'] = times[0]
    geojson['mint_properties']['end_time'] = times[-1]
    geojson['mint_properties']['time_format'] = 'YYYY-MM-DD'
    geojson['features'] = []
    # feature = {}
    # feature['type'] = 'Feature'
    # feature['properties'] = {}
    # feature['properties']['value'] = []
    # feature['geometry'] = {}
    # feature['geometry']['type'] = 'Point'
    mint_id = 0
    for k, v in data.items():
        feature = {}
        feature['type'] = 'Feature'
        feature['properties'] = {}
        feature['properties']['mint_value'] = [] 
        feature['properties']['mint_id'] = mint_id
        feature['geometry'] = {}
        feature['geometry']['type'] = 'Point'
        lon, lat = get_lon_lat(k)
        feature['geometry']['coordinates'] = [lon, lat]
        feature['properties']['values'] = {}
        for item in v:
            feature['properties']['mint_value'].append([item[1], 1 if item[2] else 0])
        geojson['features'].append(feature)
        mint_id += 1
    return geojson


def get_lon_lat(point):
        left = point.find('(')
        right = point.find(')')
        lon = point[left + 1 : right].split(' ')[0]
        lat = point[left + 1 : right].split(' ')[1]
        return float(lon), float(lat)

def read_csv(csv_file, contain_header):
    data = {}
    times = []
    values = []
    with open(csv_file) as f:
        reader = csv.reader(f)
        if contain_header:
            next(f)
        for row in reader:
            # 2016-01-01,4.0,0, POINT (27.111772120892855 9.155444982492638) 
            time, value, is_interpolation, point = row[0], float(row[1]), bool(row[2]), row[3]
            times.append(time)
            values.append(value)
            if data.get(point):
                data[point].append([time, value, is_interpolation])
            else:
                data[point] = [[time, value, is_interpolation]]
    times = list(set(times))
    return data, times, values


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print(USAGE)

    input_file = sys.argv[1]
    contain_header = sys.argv[2]
    output_file = sys.argv[3]

    main(input_file, contain_header, output_file)
    