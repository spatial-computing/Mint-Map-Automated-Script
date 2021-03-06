#!/usr/bin/env python3
import os,sys


def main():
	method = sys.argv[1]
	path = sys.argv[2]
	if method == 'basename':
		print(os.path.basename(path),file=sys.stdout)
	elif method == 'dir':
		print(os.path.dirname(path),file=sys.stdout)
	elif method == 'diff':
		path2 = sys.argv[3]
		if len(path2[3]) < len(path) :
			path2 = path
			path = sys.argv[3]
		print(path2[len(path):])
	elif method == 'ext':
		_name, _ext = os.path.splitext(path)
		print(_ext,file=sys.stdout)
	elif method == 'toplevel':
		path_split = path.split('/')
		if len(path_split) == 0:
			print("/")
			return
		print("/" + (path_split[0] or (path_split[1] if len(path_split) > 1 else "")), file=sys.stdout)

usage = '''
main.py basename [path]
main.py dir [path]
main.py diff [path1] [path2]
'''
if __name__ == '__main__':
	num_args = len(sys.argv)

	if num_args < 3:
		print(usage)
		exit(1)

	main()