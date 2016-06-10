CREATE OR REPLACE FUNCTION cdb_dataservices_client._augmentation_server_conn_json()
RETURNS json AS $$
DECLARE
  db_connection_json text;
BEGIN
  SELECT cartodb.cdb_conf_getconf('fdws')->'augment' INTO db_connection_json;
  RETURN db_connection_json;
END;
$$ LANGUAGE 'plpgsql';
