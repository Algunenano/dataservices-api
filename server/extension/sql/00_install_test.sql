-- Install dependencies
CREATE EXTENSION postgis;
CREATE EXTENSION schema_triggers;
CREATE EXTENSION plpythonu;
CREATE EXTENSION cartodb;
CREATE EXTENSION cdb_geocoder;

-- Install the extension
CREATE EXTENSION cdb_geocoder_server;

-- Mock the varnish invalidation function
-- (used by cdb_geocoder tests)
CREATE OR REPLACE FUNCTION public.cdb_invalidate_varnish(table_name text) RETURNS void AS $$
BEGIN
  RETURN;
END
$$
LANGUAGE plpgsql;

-- Set user quota
SELECT cartodb.CDB_SetUserQuotaInBytes(0);
