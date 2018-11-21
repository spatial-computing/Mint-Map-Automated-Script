--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.13
-- Dumped by pg_dump version 10.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: metadata; Type: TABLE; Schema: mintcast; Owner: vaccaro
--

CREATE TABLE mintcast.metadata (
    k character varying(32) NOT NULL,
    v text
);

--
-- Data for Name: metadata; Type: TABLE DATA; Schema: mintcast; Owner: vaccaro
--

COPY mintcast.metadata (k, v) FROM stdin;
server	
tileurl	/{z}/{x}/{y}
port	
config_file_location	
mbtiles_location	
metajson_location	
border_features	{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"stroke":"#000000","stroke-width":3,"stroke-opacity":1,"fill":"#555555","fill-opacity":0.3},"geometry":{"type":"Polygon","coordinates":[]}}]}
\.


--
-- Name: metadata metadata_pkey; Type: CONSTRAINT; Schema: mintcast; Owner: vaccaro
--

ALTER TABLE ONLY mintcast.metadata
    ADD CONSTRAINT metadata_pkey PRIMARY KEY (k);

CREATE SEQUENCE mintcast.original_seq;

CREATE TABLE mintcast.original (
    id integer DEFAULT nextval('mintcast.original_seq'::regclass) NOT NULL,
    dataset_name character varying(255),
    filename character varying(255) NOT NULL,
    filepath character varying(255) NOT NULL,
    gdalinfo text,
    related_json text,
    create_at timestamp(0) without time zone DEFAULT now(),
    modified_at timestamp(0) without time zone DEFAULT now()
);

ALTER SEQUENCE mintcast.original_seq
    OWNED BY mintcast.original.id;
--
-- Name: original original_pkey; Type: CONSTRAINT; Schema: mintcast; Owner: vaccaro
--

ALTER TABLE ONLY mintcast.original
    ADD CONSTRAINT original_pkey PRIMARY KEY (id);

--
-- Name: tileserverconfig; Type: TABLE; Schema: mintcast; Owner: vaccaro
--
CREATE SEQUENCE mintcast.tileserverconfig_seq;


CREATE TABLE mintcast.tileserverconfig (
    id integer DEFAULT nextval('mintcast.tileserverconfig_seq'::regclass) NOT NULL,
    layerid character varying(255) NOT NULL,
    mbtiles character varying(255) NOT NULL,
    md5 character varying(255) NOT NULL
);

ALTER SEQUENCE mintcast.tileserverconfig_seq
    OWNED BY mintcast.tileserverconfig.id;
--
-- Name: tileserverconfig tileserverconfig_pkey; Type: CONSTRAINT; Schema: mintcast; Owner: vaccaro
--

ALTER TABLE ONLY mintcast.tileserverconfig
    ADD CONSTRAINT tileserverconfig_pkey PRIMARY KEY (id);

--
-- Name: layer; Type: TABLE; Schema: mintcast; Owner: vaccaro
--
CREATE SEQUENCE mintcast.layer_seq;

CREATE TABLE mintcast.layer (
    id integer DEFAULT nextval('mintcast.layer_seq'::regclass) NOT NULL,
    layerid character varying(255) NOT NULL DEFAULT ''::character varying,
    processing_flag smallint DEFAULT 0,
    isdiff smallint DEFAULT 0,
    diff_layerid character varying(255) NOT NULL DEFAULT ''::character varying,
    original_id integer DEFAULT NULL,
    type character varying(8) DEFAULT 'vector'::character varying,
    tileformat character varying(8) DEFAULT 'pdf'::character varying,
    name character varying(255) NOT NULL,
    stdname character varying(255) NOT NULL,
    md5 character varying(255) NOT NULL,
    sourcelayer character varying(64) NOT NULL,
    hasdata smallint DEFAULT 0,
    hastimeline smallint DEFAULT 0,
    maxzoom integer DEFAULT 14,
    minzoom integer DEFAULT 3,
    bounds character varying(255),
    mbfilename character varying(255),
    directory_format character varying(255),
    starttime timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    endtime timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    json_filename character varying(255),
    server character varying(255),
    tileurl character varying(255),
    styletype character varying(32) DEFAULT 'fill'::character varying,
    legend_type character varying(16) DEFAULT 'linear'::character varying,
    legend text,
    uri text,
    valuearray text,
    vector_json text,
    colormap text,
    hotspot text,
    original_dataset_bounds text,
    mapping character varying(64),
    create_at timestamp(0) without time zone DEFAULT now(),
    modified_at timestamp(0) without time zone DEFAULT now(),
    steptype character varying(32) DEFAULT NULL::character varying,
    stepoption_type character varying(16) DEFAULT NULL::character varying,
    stepoption_format character varying(16) DEFAULT NULL::character varying,
    step character varying(255) DEFAULT NULL::character varying,
    axis character varying(32) DEFAULT NULL::character varying
);

--
-- Name: layer layer_pkey; Type: CONSTRAINT; Schema: mintcast; Owner: vaccaro
--
ALTER SEQUENCE mintcast.layer_seq
    OWNED BY mintcast.layer.id;

ALTER TABLE ONLY mintcast.layer
    ADD CONSTRAINT layer_pkey PRIMARY KEY (id);



--
-- PostgreSQL database dump complete
--

