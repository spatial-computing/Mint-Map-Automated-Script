#!/usr/bin/env python3

import sys
import csv
import json


USAGE = """python3 ./python/macro_csv_timeseries_geojson csv_filepath output_dir"""


def main(csv_file, contain_header, output_file):
    data, start_time, end_time = read_csv(csv_file, contain_header)
    geojson = generate_point_geojson(data, start_time, end_time)

    with open(output_file, 'w') as f:
        json.dump(geojson, f)


def generate_point_geojson(data, start_time, end_time):
    geojson = {}
    geojson['type'] = 'FeatureCollection'
    geojson['properties'] = {}
    geojson['properties']['start_time'] = start_time
    geojson['properties']['end_time'] = end_time
    geojson['properties']['time_format'] = 'YYYY-MM-DD'
    geojson['features'] = []
    feature = {}
    feature['type'] = 'Feature'
    feature['properties'] = {}
    feature['properties']['values'] = {}
    feature['geometry'] = {}
    feature['geometry']['type'] = 'Point'

    for k, v in data.items():
        feature = {}
        feature['type'] = 'Feature'
        feature['properties'] = {}
        feature['properties']['values'] = {}
        feature['geometry'] = {}
        feature['geometry']['type'] = 'Point'
        lon, lat = get_lon_lat(k)
        feature['geometry']['coordinates'] = [lon, lat]
        feature['properties']['values'] = {}
        for item in v:
            feature['properties']['values'][item[0]] = {"value": item[1], "is_interpolation": item[2]}
        geojson['features'].append(feature)
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
    with open(csv_file) as f:
        reader = csv.reader(f)
        if contain_header:
            next(f)
        for row in reader:
            # 2016-01-01,4.0,0, POINT (27.111772120892855 9.155444982492638) 
            time, value, is_interpolation, point = row[0], float(row[1]), bool(row[2]), row[3]
            times.append(time)
            if data.get(point):
                data[point].append([time, value, is_interpolation])
            else:
                data[point] = [[time, value, is_interpolation]]
    times = list(set(times))
    start_time = min(times)
    end_time = max(times)
    return data, start_time, end_time


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print(USAGE)

    input_file = sys.argv[1]
    contain_header = sys.argv[2]
    output_file = sys.argv[3]

    main(input_file, contain_header, output_file)