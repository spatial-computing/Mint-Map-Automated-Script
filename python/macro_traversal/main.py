#!/usr/bin/env python3

# argv [./main.py, 'dir','dir structure', 'start', 'end']

import sys
import os
import re
from os.path import isfile, join, expanduser
from datetime import datetime, date, time, timedelta
monthdelta_dict = {
	0: timedelta(days=0),
	1: timedelta(days=31),
	2: timedelta(days=28),
	3: timedelta(days=31),
	4: timedelta(days=30),
	5: timedelta(days=31),
	6: timedelta(days=30),
	7: timedelta(days=31),
	8: timedelta(days=31),
	9: timedelta(days=30),
	10: timedelta(days=31),
	11: timedelta(days=30),
	12: timedelta(days=31)
}
def daterange(start_date, end_date, delta):
	# days = (end_date - start_date).days
	date_diff = end_date - start_date
	if delta == "days":
	    for n in range(date_diff.days):
	        yield start_date
	        start_date += timedelta(days=1)
	elif delta == "months":
		sdm = 0
		month_delta = monthdelta_dict[sdm]

		while date_diff - month_delta >= timedelta(0):
			yield start_date + month_delta
			start_date += month_delta

			sdm += 1
			sdm = sdm % 12 if sdm % 12 != 0 else 1

			month_delta = monthdelta_dict[sdm]
			date_diff -= month_delta
		yield start_date + month_delta
		# for n in range():
		#   yield start_date + timedelta(n)
	elif delta == "years":
		year_delta = timedelta(days=365)
		while date_diff - year_delta >= timedelta(0):
			yield start_date + year_delta
			start_date += year_delta

			date_diff -= year_delta

		yield start_date + year_delta
		# for n in range(days):
	 #        yield start_date + timedelta(n)
	   
def main(argv):
	_dir = expanduser(sys.argv[1])

	_wildcardPathStructure = sys.argv[2].replace('{year}','%Y').replace('{month}', '%m').replace('{day}','%d')
	
	__timeFormat = sys.argv[5].replace('{year}','%Y').replace('{month}', '%m').replace('{day}','%d')
	# _structure = os.path.dirname(_wildcardStructure)
	# if len(sys.argv) == 6:
	# 	# if there are six parameter, then year and month
	# 	_structure = sys.argv[5].replace('{year}','%Y').replace('{month}', '%m').replace('{day}','%d')
	
	_structure = _wildcardPathStructure

	#_structure.replace('/', '')
	_start = datetime.strptime(sys.argv[3], __timeFormat)
	_end = datetime.strptime(sys.argv[4], __timeFormat)

	_filetype = os.path.splitext(sys.argv[2])[1]

	files = []
	_oldpath = ''
	_path = _dir

	_delta = 'days'
	if __timeFormat.find('%d') != -1:
		_delta = 'days'
	elif __timeFormat.find('%m') != -1:
		_delta = 'months'
	elif __timeFormat.find('%Y') != -1:
		_delta = 'years'


	for single_date in daterange(_start, _end, delta=_delta):
		_file = single_date.strftime(_structure)
		_path = join(_dir, _file)

		if _oldpath == _path:
			continue

		if isfile(_path):
			print(_path)

		# for f in os.listdir(_path):
		# 	if isfile(join(_path,f)):
		# 		if os.path.splitext(f)[1]==_filetype:
		# 			print(join(_path,f))
		# 			# Then use xargs -I % cmd %
		_oldpath = _path

	# if len(sys.argv) == 6:
	# 	for f in os.listdir(_path):
	# 		if isfile(join(_path,f)):
	# 			if os.path.splitext(f)[1]==_filetype:
	# 				print(join(_path,f))
	# 				# Then use xargs -I % cmd %
	# else:
	# 	for single_date in daterange(_start, _end):
	# 		_folder = single_date.strftime(_structure)
	# 		_path = _dir + _folder
	# 		if _oldpath == _path:
	# 			continue

	# 		for f in os.listdir(_path):
	# 			if isfile(join(_path,f)):
	# 				if os.path.splitext(f)[1]==_filetype:
	# 					print(join(_path,f))
	# 					# Then use xargs -I % cmd %
	# 		_oldpath = _path
if __name__ == '__main__':
	main(sys.argv)