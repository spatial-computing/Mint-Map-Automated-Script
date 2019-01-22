import TileStache

if __name__ == '__main__':
	application = TileStache.WSGITileServer("/data/tilestache.json", autoreload=True)