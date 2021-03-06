PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE `metadata`(`k` TEXT PRIMARY KEY, `v` TEXT);
INSERT INTO metadata VALUES('border_features','{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"stroke":"#000000","stroke-width":3,"stroke-opacity":1,"fill":"#555555","fill-opacity":0.3},"geometry":{"type":"Polygon","coordinates":[]}}]}');
INSERT INTO metadata VALUES('config_file_location','');
INSERT INTO metadata VALUES('mbtiles_location','');
INSERT INTO metadata VALUES('metajson_location','');
INSERT INTO metadata VALUES('port','');
INSERT INTO metadata VALUES('server','');
INSERT INTO metadata VALUES('tileurl','/{z}/{x}/{y}');
CREATE TABLE `layer`(`id` INTEGER PRIMARY KEY, `layerid` TEXT, `type` TEXT, `tileformat` TEXT, `name` TEXT, `sourceLayer` TEXT, `original_id` INTEGER, `hasData` BOOLEAN, `hasTimeline` BOOLEAN, `maxzoom` INTEGER, `minzoom` INTEGER, `bounds` TEXT, `mbfilename` TEXT, `directory_format` TEXT, `starttime` TEXT, `endtime` TEXT, `json_filename` TEXT, `server` TEXT, `tileurl` TEXT, `styleType` TEXT, `legend_type` TEXT, `legend` TEXT, `valueArray` TEXT, `vector_json` TEXT, `colormap` TEXT, `original_dataset_bounds` TEXT, `mapping` TEXT, `ckan_url` TEXT, `create_at` DATETIME DEFAULT current_timestamp, `modified_at` DATETIME DEFAULT current_timestamp);
CREATE TABLE `original`(`id` INTEGER PRIMARY KEY , `dataset_name` TEXT, `filename` TEXT, `filepath` TEXT, `gdalinfo` TEXT, `related_json` TEXT, `create_at` DATETIME DEFAULT current_timestamp, `modified_at` DATETIME DEFAULT current_timestamp);


CREATE TABLE `tileserverconfig` (`id` INTEGER PRIMARY KEY , `layerid` TEXT, `mbtiles` TEXT, `md5` TEXT);
COMMIT;
