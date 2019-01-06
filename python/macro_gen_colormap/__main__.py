#!/usr/bin/env python3

import sys
import os
import tempfile

MINTCAST_PATH = os.environ.get('MINTCAST_PATH')

ZERO_PERSENTAGE_LINE = '0% 0 0 0 255'
HUNDRED_PERSENTAGE_LINE = '100% 255 255 255 255'

RGBA = {
    "NV_LINE" : 'nv 0 0 0 0 #No Value',
    "BLACK_LINE" : ' 0 0 0 255',
    "WHITE_LINE" : ' 255 255 255 255',
    "GREEN_LINE" : ' 0 255 0 255',
    "BLUE_LINE" : ' 0 0 255 255',
    "RED_LINE" : ' 255 0 0 255',
    "YELLOW_LINE" : ' 255 255 0 255',
}

def main(type_of_colormap, valueList):
    temp_name = next(tempfile._get_candidate_names())
    temp_name = MINTCAST_PATH + '/tmp/' + temp_name
    with open(temp_name, 'w') as tmpfile:
        nvline = RGBA["NV_LINE"] + "\n"
        tmpfile.write(nvline)
        for idx, val in enumerate(valueList):
            color = type_of_colormap[idx%len(type_of_colormap)]
            newline = val + RGBA[color + "_LINE"] + "\n"
            tmpfile.write(newline)
        
        # tmpfile.seek(0)
        # print(tmpfile.read())
        print(temp_name)


USAGE = '''
python3 macro_gen_colormap type_of_colormap max min 
'''

if __name__ == '__main__':
    if not MINTCAST_PATH:
        raise Exception('NO MINTCAST_PATH')
        exit(1)
    if len(sys.argv) == 3:
        main(list(map(str.upper, sys.argv[1].split(' '))), sys.argv[2].split(' '))
    else:
        raise Exception(USAGE.strip())
