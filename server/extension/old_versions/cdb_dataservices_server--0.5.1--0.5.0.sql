--DO NOT MODIFY THIS FILE, IT IS GENERATED AUTOMATICALLY FROM SOURCES
-- Complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "ALTER EXTENSION cdb_dataservices_server UPDATE TO '0.5.0'" to load this file. \quit
DROP FUNCTION IF EXISTS cdb_dataservices_server._get_internal_geocoder_config(text, text);

CREATE TYPE cdb_dataservices_server._redis_conf_params AS (
    sentinel_master_id text,
    redis_host text,
    redis_port int,
    redis_db text,
    timeout float
);

-- Get the Redis configuration from the _conf table --
CREATE OR REPLACE FUNCTION cdb_dataservices_server._get_redis_conf_v2(config_key text)
RETURNS cdb_dataservices_server._redis_conf_params AS $$
    conf_query = "SELECT cartodb.CDB_Conf_GetConf('{0}') as conf".format(config_key)
    conf = plpy.execute(conf_query)[0]['conf']
    if conf is None:
      plpy.error("There is no redis configuration defined")
    else:
      import json
      params = json.loads(conf)
      redis_conf_params = {
        "redis_host": params['redis_host'],
        "redis_port": params['redis_port'],
        "timeout": params['timeout'],
        "redis_db": params['redis_db']
      }
      if "sentinel_master_id" in params:
        redis_conf_params["sentinel_master_id"] = params["sentinel_master_id"]
      else:
        redis_conf_params["sentinel_master_id"] = None

      return redis_conf_params
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server._connect_to_redis(user_id text)
RETURNS boolean AS $$
  cache_key = "redis_connection_{0}".format(user_id)
  if cache_key in GD:
    return False
  else:
    from cartodb_services.tools import RedisConnection
    metadata_config_params = plpy.execute("""select c.sentinel_master_id, c.redis_host, 
        c.redis_port, c.timeout, c.redis_db
        from cdb_dataservices_server._get_redis_conf_v2('redis_metadata_config') c;""")[0]
    metrics_config_params = plpy.execute("""select c.sentinel_master_id, c.redis_host, 
        c.redis_port, c.timeout, c.redis_db
        from cdb_dataservices_server._get_redis_conf_v2('redis_metrics_config') c;""")[0]
    redis_metadata_connection = RedisConnection(metadata_config_params['sentinel_master_id'],
        metadata_config_params['redis_host'],
        metadata_config_params['redis_port'],
        timeout=metadata_config_params['timeout'],
        redis_db=metadata_config_params['redis_db']).redis_connection()
    redis_metrics_connection = RedisConnection(metrics_config_params['sentinel_master_id'],
        metrics_config_params['redis_host'],
        metrics_config_params['redis_port'],
        timeout=metrics_config_params['timeout'],
        redis_db=metrics_config_params['redis_db']).redis_connection()
    GD[cache_key] = {
      'redis_metadata_connection': redis_metadata_connection,
      'redis_metrics_connection': redis_metrics_connection,
    }
    return True
$$ LANGUAGE plpythonu SECURITY DEFINER;

-- Get the Redis configuration from the _conf table --
CREATE OR REPLACE FUNCTION cdb_dataservices_server._get_geocoder_config(username text, orgname text)
RETURNS boolean AS $$
  cache_key = "user_geocoder_config_{0}".format(username)
  if cache_key in GD:
    return False
  else:
    import json
    from cartodb_services.metrics import GeocoderConfig
    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metadata_connection']
    heremaps_conf_json = plpy.execute("SELECT cartodb.CDB_Conf_GetConf('heremaps_conf') as heremaps_conf", 1)[0]['heremaps_conf']
    if not heremaps_conf_json:
      heremaps_app_id = None
      heremaps_app_code = None
    else:
      heremaps_conf = json.loads(heremaps_conf_json)
      heremaps_app_id = heremaps_conf['app_id']
      heremaps_app_code = heremaps_conf['app_code']
    geocoder_config = GeocoderConfig(redis_conn, username, orgname, heremaps_app_id, heremaps_app_code)
    # --Think about the security concerns with this kind of global cache, it should be only available
    # --for this user session but...
    GD[cache_key] = geocoder_config
    return True
$$ LANGUAGE plpythonu SECURITY DEFINER;

-- Get the Redis configuration from the _conf table --
CREATE OR REPLACE FUNCTION cdb_dataservices_server._get_isolines_routing_config(username text, orgname text)
RETURNS boolean AS $$
  cache_key = "user_isolines_routing_config_{0}".format(username)
  if cache_key in GD:
    return False
  else:
    import json
    from cartodb_services.metrics import IsolinesRoutingConfig
    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metadata_connection']
    heremaps_conf_json = plpy.execute("SELECT cartodb.CDB_Conf_GetConf('heremaps_conf') as heremaps_conf", 1)[0]['heremaps_conf']
    if not heremaps_conf_json:
      heremaps_app_id = None
      heremaps_app_code = None
    else:
      heremaps_conf = json.loads(heremaps_conf_json)
      heremaps_app_id = heremaps_conf['app_id']
      heremaps_app_code = heremaps_conf['app_code']
    isolines_routing_config = IsolinesRoutingConfig(redis_conn, username, orgname, heremaps_app_id, heremaps_app_code)
    # --Think about the security concerns with this kind of global cache, it should be only available
    # --for this user session but...
    GD[cache_key] = isolines_routing_config
    return True
$$ LANGUAGE plpythonu SECURITY DEFINER;

-- Get the Redis configuration from the _conf table --
CREATE OR REPLACE FUNCTION cdb_dataservices_server._get_routing_config(username text, orgname text)
RETURNS boolean AS $$
  cache_key = "user_routing_config_{0}".format(username)
  if cache_key in GD:
    return False
  else:
    import json
    from cartodb_services.metrics import RoutingConfig
    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metadata_connection']
    mapzen_conf_json = plpy.execute("SELECT cartodb.CDB_Conf_GetConf('mapzen_conf') as mapzen_conf", 1)[0]['mapzen_conf']
    if not mapzen_conf_json:
      mapzen_app_key = None
    else:
      mapzen_conf = json.loads(mapzen_conf_json)
      mapzen_app_key = mapzen_conf['routing_app_key']
    routing_config = RoutingConfig(redis_conn, username, orgname, mapzen_app_key)
    # --Think about the security concerns with this kind of global cache, it should be only available
    # --for this user session but...
    GD[cache_key] = routing_config
    return True
$$ LANGUAGE plpythonu SECURITY DEFINER;

CREATE OR REPLACE FUNCTION cdb_dataservices_server._cdb_here_geocode_street_point(username TEXT, orgname TEXT, searchtext TEXT, city TEXT DEFAULT NULL, state_province TEXT DEFAULT NULL, country TEXT DEFAULT NULL)
RETURNS Geometry AS $$
  from cartodb_services.here import HereMapsGeocoder
  from cartodb_services.metrics import QuotaService

  redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
  user_geocoder_config = GD["user_geocoder_config_{0}".format(username)]

  # -- Check the quota
  quota_service = QuotaService(user_geocoder_config, redis_conn)
  if not quota_service.check_user_quota():
    plpy.error('You have reach the limit of your quota')

  try:
    geocoder = HereMapsGeocoder(user_geocoder_config.heremaps_app_id, user_geocoder_config.heremaps_app_code)
    coordinates = geocoder.geocode(searchtext=searchtext, city=city, state=state_province, country=country)
    if coordinates:
      quota_service.increment_success_geocoder_use()
      plan = plpy.prepare("SELECT ST_SetSRID(ST_MakePoint($1, $2), 4326); ", ["double precision", "double precision"])
      point = plpy.execute(plan, [coordinates[0], coordinates[1]], 1)[0]
      return point['st_setsrid']
    else:
      quota_service.increment_empty_geocoder_use()
      return None
  except BaseException as e:
    import sys, traceback
    type_, value_, traceback_ = sys.exc_info()
    quota_service.increment_failed_geocoder_use()
    error_msg = 'There was an error trying to geocode using here maps geocoder: {0}'.format(e)
    plpy.notice(traceback.format_tb(traceback_))
    plpy.error(error_msg)
  finally:
    quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server._cdb_google_geocode_street_point(username TEXT, orgname TEXT, searchtext TEXT, city TEXT DEFAULT NULL, state_province TEXT DEFAULT NULL, country TEXT DEFAULT NULL)
RETURNS Geometry AS $$
  from cartodb_services.google import GoogleMapsGeocoder
  from cartodb_services.metrics import QuotaService

  redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
  user_geocoder_config = GD["user_geocoder_config_{0}".format(username)]
  quota_service = QuotaService(user_geocoder_config, redis_conn)

  try:
    geocoder = GoogleMapsGeocoder(user_geocoder_config.google_client_id, user_geocoder_config.google_api_key)
    coordinates = geocoder.geocode(searchtext=searchtext, city=city, state=state_province, country=country)
    if coordinates:
      quota_service.increment_success_geocoder_use()
      plan = plpy.prepare("SELECT ST_SetSRID(ST_MakePoint($1, $2), 4326); ", ["double precision", "double precision"])
      point = plpy.execute(plan, [coordinates[0], coordinates[1]], 1)[0]
      return point['st_setsrid']
    else:
      quota_service.increment_empty_geocoder_use()
      return None
  except BaseException as e:
    import sys, traceback
    type_, value_, traceback_ = sys.exc_info()
    quota_service.increment_failed_geocoder_use()
    error_msg = 'There was an error trying to geocode using google maps geocoder: {0}'.format(e)
    plpy.notice(traceback.format_tb(traceback_))
    plpy.error(error_msg)
  finally:
    quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_geocode_admin0_polygon(username text, orgname text, country_name text)
RETURNS Geometry AS $$
    from cartodb_services.metrics import QuotaService
    from cartodb_services.metrics import InternalGeocoderConfig

    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
    user_geocoder_config = InternalGeocoderConfig(redis_conn, username, orgname)

    quota_service = QuotaService(user_geocoder_config, redis_conn)
    try:
      plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_geocode_admin0_polygon(trim($1)) AS mypolygon", ["text"])
      rv = plpy.execute(plan, [country_name], 1)
      result = rv[0]["mypolygon"]
      if result:
        quota_service.increment_success_geocoder_use()
        return result
      else:
        quota_service.increment_empty_geocoder_use()
        return None
    except BaseException as e:
      import sys, traceback
      type_, value_, traceback_ = sys.exc_info()
      quota_service.increment_failed_geocoder_use()
      error_msg = 'There was an error trying to geocode using admin0 geocoder: {0}'.format(e)
      plpy.notice(traceback.format_tb(traceback_))
      plpy.error(error_msg)
    finally:
      quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_geocode_admin1_polygon(username text, orgname text, admin1_name text)
RETURNS Geometry AS $$
    from cartodb_services.metrics import QuotaService
    from cartodb_services.metrics import InternalGeocoderConfig

    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
    user_geocoder_config = InternalGeocoderConfig(redis_conn, username, orgname)

    quota_service = QuotaService(user_geocoder_config, redis_conn)
    try:
      plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_geocode_admin1_polygon(trim($1)) AS mypolygon", ["text"])
      rv = plpy.execute(plan, [admin1_name], 1)
      result = rv[0]["mypolygon"]
      if result:
        quota_service.increment_success_geocoder_use()
        return result
      else:
        quota_service.increment_empty_geocoder_use()
        return None
    except BaseException as e:
      import sys, traceback
      type_, value_, traceback_ = sys.exc_info()
      quota_service.increment_failed_geocoder_use()
      error_msg = 'There was an error trying to geocode using admin0 geocoder: {0}'.format(e)
      plpy.notice(traceback.format_tb(traceback_))
      plpy.error(error_msg)
    finally:
      quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_geocode_admin1_polygon(username text, orgname text, admin1_name text, country_name text)
RETURNS Geometry AS $$
    from cartodb_services.metrics import QuotaService
    from cartodb_services.metrics import InternalGeocoderConfig

    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
    user_geocoder_config = InternalGeocoderConfig(redis_conn, username, orgname)

    quota_service = QuotaService(user_geocoder_config, redis_conn)
    try:
      plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_geocode_admin1_polygon(trim($1), trim($2)) AS mypolygon", ["text", "text"])
      rv = plpy.execute(plan, [admin1_name, country_name], 1)
      result = rv[0]["mypolygon"]
      if result:
        quota_service.increment_success_geocoder_use()
        return result
      else:
        quota_service.increment_empty_geocoder_use()
        return None
    except BaseException as e:
      import sys, traceback
      type_, value_, traceback_ = sys.exc_info()
      quota_service.increment_failed_geocoder_use()
      error_msg = 'There was an error trying to geocode using admin0 geocoder: {0}'.format(e)
      plpy.notice(traceback.format_tb(traceback_))
      plpy.error(error_msg)
    finally:
      quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_geocode_namedplace_point(username text, orgname text, city_name text)
RETURNS Geometry AS $$
    from cartodb_services.metrics import QuotaService
    from cartodb_services.metrics import InternalGeocoderConfig

    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
    user_geocoder_config = InternalGeocoderConfig(redis_conn, username, orgname)

    quota_service = QuotaService(user_geocoder_config, redis_conn)
    try:
      plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_geocode_namedplace_point(trim($1)) AS mypoint", ["text"])
      rv = plpy.execute(plan, [city_name], 1)
      result = rv[0]["mypoint"]
      if result:
        quota_service.increment_success_geocoder_use()
        return result
      else:
        quota_service.increment_empty_geocoder_use()
        return None
    except BaseException as e:
      import sys, traceback
      type_, value_, traceback_ = sys.exc_info()
      quota_service.increment_failed_geocoder_use()
      error_msg = 'There was an error trying to geocode using admin0 geocoder: {0}'.format(e)
      plpy.notice(traceback.format_tb(traceback_))
      plpy.error(error_msg)
    finally:
      quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_geocode_namedplace_point(username text, orgname text, city_name text, country_name text)
RETURNS Geometry AS $$
    from cartodb_services.metrics import QuotaService
    from cartodb_services.metrics import InternalGeocoderConfig

    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
    user_geocoder_config = InternalGeocoderConfig(redis_conn, username, orgname)

    quota_service = QuotaService(user_geocoder_config, redis_conn)
    try:
      plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_geocode_namedplace_point(trim($1), trim($2)) AS mypoint", ["text", "text"])
      rv = plpy.execute(plan, [city_name, country_name], 1)
      result = rv[0]["mypoint"]
      if result:
        quota_service.increment_success_geocoder_use()
        return result
      else:
        quota_service.increment_empty_geocoder_use()
        return None
    except BaseException as e:
      import sys, traceback
      type_, value_, traceback_ = sys.exc_info()
      quota_service.increment_failed_geocoder_use()
      error_msg = 'There was an error trying to geocode using admin0 geocoder: {0}'.format(e)
      plpy.notice(traceback.format_tb(traceback_))
      plpy.error(error_msg)
    finally:
      quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_geocode_namedplace_point(username text, orgname text, city_name text, admin1_name text, country_name text)
RETURNS Geometry AS $$
    from cartodb_services.metrics import QuotaService
    from cartodb_services.metrics import InternalGeocoderConfig

    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
    user_geocoder_config = InternalGeocoderConfig(redis_conn, username, orgname)

    quota_service = QuotaService(user_geocoder_config, redis_conn)
    try:
      plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_geocode_namedplace_point(trim($1), trim($2), trim($3)) AS mypoint", ["text", "text", "text"])
      rv = plpy.execute(plan, [city_name, admin1_name, country_name], 1)
      result = rv[0]["mypoint"]
      if result:
        quota_service.increment_success_geocoder_use()
        return result
      else:
        quota_service.increment_empty_geocoder_use()
        return None
    except BaseException as e:
      import sys, traceback
      type_, value_, traceback_ = sys.exc_info()
      quota_service.increment_failed_geocoder_use()
      error_msg = 'There was an error trying to geocode using admin0 geocoder: {0}'.format(e)
      plpy.notice(traceback.format_tb(traceback_))
      plpy.error(error_msg)
    finally:
      quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_geocode_postalcode_point(username text, orgname text, code text)
RETURNS Geometry AS $$
    from cartodb_services.metrics import QuotaService
    from cartodb_services.metrics import InternalGeocoderConfig

    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
    user_geocoder_config = InternalGeocoderConfig(redis_conn, username, orgname)

    quota_service = QuotaService(user_geocoder_config, redis_conn)
    try:
      plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_geocode_postalcode_point(trim($1)) AS mypoint", ["text"])
      rv = plpy.execute(plan, [code], 1)
      result = rv[0]["mypoint"]
      if result:
        quota_service.increment_success_geocoder_use()
        return result
      else:
        quota_service.increment_empty_geocoder_use()
        return None
    except BaseException as e:
      import sys, traceback
      type_, value_, traceback_ = sys.exc_info()
      quota_service.increment_failed_geocoder_use()
      error_msg = 'There was an error trying to geocode using admin0 geocoder: {0}'.format(e)
      plpy.notice(traceback.format_tb(traceback_))
      plpy.error(error_msg)
    finally:
      quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_geocode_postalcode_point(username text, orgname text, code text, country text)
RETURNS Geometry AS $$
    from cartodb_services.metrics import QuotaService
    from cartodb_services.metrics import InternalGeocoderConfig

    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
    user_geocoder_config = InternalGeocoderConfig(redis_conn, username, orgname)

    quota_service = QuotaService(user_geocoder_config, redis_conn)
    try:
      plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_geocode_postalcode_point(trim($1), trim($2)) AS mypoint", ["TEXT", "TEXT"])
      rv = plpy.execute(plan, [code, country], 1)
      result = rv[0]["mypoint"]
      if result:
        quota_service.increment_success_geocoder_use()
        return result
      else:
        quota_service.increment_empty_geocoder_use()
        return None
    except BaseException as e:
      import sys, traceback
      type_, value_, traceback_ = sys.exc_info()
      quota_service.increment_failed_geocoder_use()
      error_msg = 'There was an error trying to geocode using admin0 geocoder: {0}'.format(e)
      plpy.notice(traceback.format_tb(traceback_))
      plpy.error(error_msg)
    finally:
      quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_geocode_postalcode_polygon(username text, orgname text, code text)
RETURNS Geometry AS $$
    from cartodb_services.metrics import QuotaService
    from cartodb_services.metrics import InternalGeocoderConfig

    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
    user_geocoder_config = InternalGeocoderConfig(redis_conn, username, orgname)

    quota_service = QuotaService(user_geocoder_config, redis_conn)
    try:
      plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_geocode_postalcode_polygon(trim($1)) AS mypolygon", ["text"])
      rv = plpy.execute(plan, [code], 1)
      result = rv[0]["mypolygon"]
      if result:
        quota_service.increment_success_geocoder_use()
        return result
      else:
        quota_service.increment_empty_geocoder_use()
        return None
    except BaseException as e:
      import sys, traceback
      type_, value_, traceback_ = sys.exc_info()
      quota_service.increment_failed_geocoder_use()
      error_msg = 'There was an error trying to geocode using admin0 geocoder: {0}'.format(e)
      plpy.notice(traceback.format_tb(traceback_))
      plpy.error(error_msg)
    finally:
      quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_geocode_postalcode_polygon(username text, orgname text, code text, country text)
RETURNS Geometry AS $$
    from cartodb_services.metrics import QuotaService
    from cartodb_services.metrics import InternalGeocoderConfig

    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
    user_geocoder_config = InternalGeocoderConfig(redis_conn, username, orgname)

    quota_service = QuotaService(user_geocoder_config, redis_conn)
    try:
      plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_geocode_postalcode_polygon(trim($1), trim($2)) AS mypolygon", ["TEXT", "TEXT"])
      rv = plpy.execute(plan, [code, country], 1)
      result = rv[0]["mypolygon"]
      if result:
        quota_service.increment_success_geocoder_use()
        return result
      else:
        quota_service.increment_empty_geocoder_use()
        return None
    except BaseException as e:
      import sys, traceback
      type_, value_, traceback_ = sys.exc_info()
      quota_service.increment_failed_geocoder_use()
      error_msg = 'There was an error trying to geocode using admin0 geocoder: {0}'.format(e)
      plpy.notice(traceback.format_tb(traceback_))
      plpy.error(error_msg)
    finally:
      quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_geocode_ipaddress_point(username text, orgname text, ip text)
RETURNS Geometry AS $$
    from cartodb_services.metrics import QuotaService
    from cartodb_services.metrics import InternalGeocoderConfig

    plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
    redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
    user_geocoder_config = InternalGeocoderConfig(redis_conn, username, orgname)

    quota_service = QuotaService(user_geocoder_config, redis_conn)
    try:
      plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_geocode_ipaddress_point(trim($1)) AS mypoint", ["TEXT"])
      rv = plpy.execute(plan, [ip], 1)
      result = rv[0]["mypoint"]
      if result:
        quota_service.increment_success_geocoder_use()
        return result
      else:
        quota_service.increment_empty_geocoder_use()
        return None
    except BaseException as e:
      import sys, traceback
      type_, value_, traceback_ = sys.exc_info()
      quota_service.increment_failed_geocoder_use()
      error_msg = 'There was an error trying to geocode using admin0 geocoder: {0}'.format(e)
      plpy.notice(traceback.format_tb(traceback_))
      plpy.error(error_msg)
    finally:
      quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION cdb_dataservices_server._cdb_here_routing_isolines(username TEXT, orgname TEXT, type TEXT, source geometry(Geometry, 4326), mode TEXT, data_range integer[], options text[])
RETURNS SETOF cdb_dataservices_server.isoline AS $$
  import json
  from cartodb_services.here import HereMapsRoutingIsoline
  from cartodb_services.metrics import QuotaService
  from cartodb_services.here.types import geo_polyline_to_multipolygon

  redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
  user_isolines_routing_config = GD["user_isolines_routing_config_{0}".format(username)]

  # -- Check the quota
  quota_service = QuotaService(user_isolines_routing_config, redis_conn)
  if not quota_service.check_user_quota():
    plpy.error('You have reach the limit of your quota')

  try:
    client = HereMapsRoutingIsoline(user_isolines_routing_config.heremaps_app_id, user_isolines_routing_config.heremaps_app_code, base_url = HereMapsRoutingIsoline.PRODUCTION_ROUTING_BASE_URL)

    if source:
      lat = plpy.execute("SELECT ST_Y('%s') AS lat" % source)[0]['lat']
      lon = plpy.execute("SELECT ST_X('%s') AS lon" % source)[0]['lon']
      source_str = 'geo!%f,%f' % (lat, lon)
    else:
      source_str = None

    if type == 'isodistance':
      resp = client.calculate_isodistance(source_str, mode, data_range, options)
    elif type == 'isochrone':
      resp = client.calculate_isochrone(source_str, mode, data_range, options)

    if resp:
      result = []
      for isoline in resp:
        data_range_n = isoline['range']
        polyline = isoline['geom']
        multipolygon = geo_polyline_to_multipolygon(polyline)
        result.append([source, data_range_n, multipolygon])
      quota_service.increment_success_geocoder_use()
      quota_service.increment_isolines_service_use(len(resp))
      return result
    else:
      quota_service.increment_empty_geocoder_use()
  except BaseException as e:
    import sys, traceback
    type_, value_, traceback_ = sys.exc_info()
    quota_service.increment_failed_geocoder_use()
    error_msg = 'There was an error trying to obtain isodistances using here maps geocoder: {0}'.format(e)
    plpy.notice(traceback.format_tb(traceback_))
    plpy.error(error_msg)
  finally:
    quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu SECURITY DEFINER;

CREATE OR REPLACE FUNCTION cdb_dataservices_server._cdb_mapzen_route_point_to_point(
  username TEXT,
  orgname TEXT,
  origin geometry(Point, 4326),
  destination geometry(Point, 4326),
  mode TEXT,
  options text[] DEFAULT ARRAY[]::text[],
  units text DEFAULT 'kilometers')
RETURNS cdb_dataservices_server.simple_route AS $$
  import json
  from cartodb_services.mapzen import MapzenRouting, MapzenRoutingResponse
  from cartodb_services.mapzen.types import polyline_to_linestring
  from cartodb_services.metrics import QuotaService
  from cartodb_services.tools import Coordinate

  redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
  user_routing_config = GD["user_routing_config_{0}".format(username)]

  quota_service = QuotaService(user_routing_config, redis_conn)

  try:
    client = MapzenRouting(user_routing_config.mapzen_app_key)

    orig_lat = plpy.execute("SELECT ST_Y('%s') AS lat" % origin)[0]['lat']
    orig_lon = plpy.execute("SELECT ST_X('%s') AS lon" % origin)[0]['lon']
    origin_coordinates = Coordinate(orig_lon, orig_lat)
    dest_lat = plpy.execute("SELECT ST_Y('%s') AS lat" % destination)[0]['lat']
    dest_lon = plpy.execute("SELECT ST_X('%s') AS lon" % destination)[0]['lon']
    dest_coordinates = Coordinate(dest_lon, dest_lat)

    resp = client.calculate_route_point_to_point(origin_coordinates, dest_coordinates, mode, options, units)

    if resp:
      shape_linestring = polyline_to_linestring(resp.shape)
      quota_service.increment_success_geocoder_use()
      return [shape_linestring, resp.length, resp.duration]
    else:
      quota_service.increment_empty_geocoder_use()
  except BaseException as e:
    import sys, traceback
    type_, value_, traceback_ = sys.exc_info()
    quota_service.increment_failed_geocoder_use()
    error_msg = 'There was an error trying to obtain route using mapzen provider: {0}'.format(e)
    plpy.notice(traceback.format_tb(traceback_))
    plpy.error(error_msg)
  finally:
    quota_service.increment_total_geocoder_use()
$$ LANGUAGE plpythonu SECURITY DEFINER;
