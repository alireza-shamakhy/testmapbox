-- create database
sudo -u postgres -i
createuser -S -D -R -P whatif # create and note down a password for database access -- whatif is a sample user name.
createdb -O whatif landcheckerdb
psql landcheckerdb

create extension postgis;
ALTER USER whatif WITH SUPERUSER;

-- create table
﻿DROP TABLE IF EXISTS school_locations;
CREATE TABLE school_locations (
    Education_Sector varchar(20),
    Entity_Type varchar(1),
    School_No integer, 
    School_Name varchar(255), 
    School_Type varchar(20),
    School_Status varchar(1),
    Address_Line_1 varchar(255),
    Address_Line_2 varchar(255),
    Address_Town varchar(100),
    Address_State varchar(3),
    Address_Postcode varchar(4),
    Postal_Address_Line_1 varchar(255),
    Postal_Address_Line_2 varchar(255),
    Postal_Town varchar(100),
    Postal_code varchar(3),
    Postal_Postcode varchar(4),
    Full_Phone_No varchar(20),
    LGA_ID varchar(3),
    LGA_NAME varchar(50),
    geocode_lon decimal(9,6),
    geocode_lat decimal(9,6)
);


-- import the CSV to the table school_locations
 COPY school_locations FROM 'school-locations.csv' CSV HEADER DELIMITER ','

-- Add primary key
alter table school_locations add fid serial PRIMARY KEY

-- Add geometry column
SELECT AddGeometryColumn( 'public', 'school_locations', 'the_geom', 4326, 'POINT', 2 );

-- update the_geom
UPDATE school_locations SET the_geom = ST_SetSRID(ST_Point( geocode_lon, geocode_lat),4326);

-- add index
DROP INDEX IF EXISTS index_the_geom;
CREATE INDEX index_the_geom ON school_locations USING gist(the_geom);


-- convert table school_locations to GeoJSON using ogr2ogr
ogr2ogr -t_srs EPSG:4326 -f "GeoJSON" schools.json PG:"host=localhost dbname=landcheckerdb user=whatif password=123456 port=5432" "school_locations(the_geom)"

-- tippecanoe  -- schools.mbtiles
tippecanoe -o schools.mbtiles schools.json -s EPSG:4326


-- import data to lga table : (lga - local government area boundary)
shp2pgsql -s 4326 -c -D -I LGA_2016_AUST lga| \
   psql -d landcheckerdb -h localhost -U whatif

-- to reduce the size and only keep Victoria since school_locations is for Victoria only
delete from lga where ste_name16 != 'Victoria'

-- convert table lga to GeoJSON using ogr2ogr
ogr2ogr -t_srs EPSG:4326 -f "GeoJSON" localities.json PG:"host=localhost dbname=landcheckerdb user=whatif password=123456 port=5432" "lga(geom)"

-- tippecanoe  -- localities.mbtiles
tippecanoe -o localities.mbtiles localities.json -s EPSG:4326

-- pgdump 
pg_dump -Fc -h localhost landcheckerdb -U whatif >postgis_export.dmp
--pg_restore
pg_restore -h localhost -p 5432 -U whatif -d landcheckerdb -v "postgis_export.dmp"








			 
 
