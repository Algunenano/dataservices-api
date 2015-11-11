--
-- Geocoder server connection config
--
-- The purpose of this function is provide to the PL/Proxy functions
-- the connection string needed to connect with the server

CREATE OR REPLACE FUNCTION cdb_geocoder_client._server_conn_str()
RETURNS text AS $$
DECLARE
  db_connection_str text;
BEGIN
  SELECT cdb_geocoder_client._config_get('db_server_config')->'connection_str' INTO db_connection_str;
  SELECT trim(both '"' FROM db_connection_str) INTO db_connection_str;
  RETURN db_connection_str;
END;
$$ LANGUAGE 'plpgsql';