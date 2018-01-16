-- Geocodes a street address given a searchtext and a state and/or country

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_geocode_street_point(username TEXT, orgname TEXT, searchtext TEXT, city TEXT DEFAULT NULL, state_province TEXT DEFAULT NULL, country TEXT DEFAULT NULL)
RETURNS Geometry AS $$
  from cartodb_services.metrics import metrics
  from cartodb_services.tools import Logger,LoggerConfig
  plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
  redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
  plpy.execute("SELECT cdb_dataservices_server._get_geocoder_config({0}, {1})".format(plpy.quote_nullable(username), plpy.quote_nullable(orgname)))
  user_geocoder_config = GD["user_geocoder_config_{0}".format(username)]
  plpy.execute("SELECT cdb_dataservices_server._get_logger_config()")
  logger_config = GD["logger_config"]
  logger = Logger(logger_config)

  with metrics('cdb_geocode_street_point', user_geocoder_config, logger):
    if user_geocoder_config.heremaps_geocoder:
      here_plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_here_geocode_street_point($1, $2, $3, $4, $5, $6) as point; ", ["text", "text", "text", "text", "text", "text"])
      return plpy.execute(here_plan, [username, orgname, searchtext, city, state_province, country], 1)[0]['point']
    elif user_geocoder_config.google_geocoder:
      google_plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_google_geocode_street_point($1, $2, $3, $4, $5, $6) as point; ", ["text", "text", "text", "text", "text", "text"])
      return plpy.execute(google_plan, [username, orgname, searchtext, city, state_province, country], 1)[0]['point']
    elif user_geocoder_config.mapzen_geocoder:
      mapzen_plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_mapzen_geocode_street_point($1, $2, $3, $4, $5, $6) as point; ", ["text", "text", "text", "text", "text", "text"])
      return plpy.execute(mapzen_plan, [username, orgname, searchtext, city, state_province, country], 1)[0]['point']
    elif user_geocoder_config.mapbox_geocoder:
      mapbox_plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_mapbox_geocode_street_point($1, $2, $3, $4, $5, $6) as point; ", ["text", "text", "text", "text", "text", "text"])
      return plpy.execute(mapbox_plan, [username, orgname, searchtext, city, state_province, country], 1)[0]['point']
    else:
      raise Exception('Requested geocoder is not available')

$$ LANGUAGE plpythonu STABLE PARALLEL RESTRICTED;


CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_here_geocode_street_point(username TEXT, orgname TEXT, searchtext TEXT, city TEXT DEFAULT NULL, state_province TEXT DEFAULT NULL, country TEXT DEFAULT NULL)
RETURNS Geometry AS $$
  plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
  redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
  plpy.execute("SELECT cdb_dataservices_server._get_geocoder_config({0}, {1})".format(plpy.quote_nullable(username), plpy.quote_nullable(orgname)))
  user_geocoder_config = GD["user_geocoder_config_{0}".format(username)]

  if user_geocoder_config.heremaps_geocoder:
    here_plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_here_geocode_street_point($1, $2, $3, $4, $5, $6) as point; ", ["text", "text", "text", "text", "text", "text"])
    return plpy.execute(here_plan, [username, orgname, searchtext, city, state_province, country], 1)[0]['point']
  else:
    raise Exception('Here geocoder is not available for your account.')

$$ LANGUAGE plpythonu STABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_google_geocode_street_point(username TEXT, orgname TEXT, searchtext TEXT, city TEXT DEFAULT NULL, state_province TEXT DEFAULT NULL, country TEXT DEFAULT NULL)
RETURNS Geometry AS $$
  plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
  redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
  plpy.execute("SELECT cdb_dataservices_server._get_geocoder_config({0}, {1})".format(plpy.quote_nullable(username), plpy.quote_nullable(orgname)))
  user_geocoder_config = GD["user_geocoder_config_{0}".format(username)]

  if user_geocoder_config.google_geocoder:
    google_plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_google_geocode_street_point($1, $2, $3, $4, $5, $6) as point; ", ["text", "text", "text", "text", "text", "text"])
    return plpy.execute(google_plan, [username, orgname, searchtext, city, state_province, country], 1)[0]['point']
  else:
    raise Exception('Google geocoder is not available for your account.')

$$ LANGUAGE plpythonu STABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_mapzen_geocode_street_point(username TEXT, orgname TEXT, searchtext TEXT, city TEXT DEFAULT NULL, state_province TEXT DEFAULT NULL, country TEXT DEFAULT NULL)
RETURNS Geometry AS $$
  # The configuration is retrieved but no checks are performed on it
  plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
  redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
  plpy.execute("SELECT cdb_dataservices_server._get_geocoder_config({0}, {1})".format(plpy.quote_nullable(username), plpy.quote_nullable(orgname)))
  user_geocoder_config = GD["user_geocoder_config_{0}".format(username)]

  mapzen_plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_mapzen_geocode_street_point($1, $2, $3, $4, $5, $6) as point; ", ["text", "text", "text", "text", "text", "text"])
  return plpy.execute(mapzen_plan, [username, orgname, searchtext, city, state_province, country], 1)[0]['point']

$$ LANGUAGE plpythonu STABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_mapbox_geocode_street_point(username TEXT, orgname TEXT, searchtext TEXT, city TEXT DEFAULT NULL, state_province TEXT DEFAULT NULL, country TEXT DEFAULT NULL)
RETURNS Geometry AS $$
  # The configuration is retrieved but no checks are performed on it
  plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
  redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
  plpy.execute("SELECT cdb_dataservices_server._get_geocoder_config({0}, {1})".format(plpy.quote_nullable(username), plpy.quote_nullable(orgname)))
  user_geocoder_config = GD["user_geocoder_config_{0}".format(username)]

  mapzen_plan = plpy.prepare("SELECT cdb_dataservices_server._cdb_mapbox_geocode_street_point($1, $2, $3, $4, $5, $6) as point; ", ["text", "text", "text", "text", "text", "text"])
  return plpy.execute(mapzen_plan, [username, orgname, searchtext, city, state_province, country], 1)[0]['point']

$$ LANGUAGE plpythonu STABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION cdb_dataservices_server._cdb_here_geocode_street_point(username TEXT, orgname TEXT, searchtext TEXT, city TEXT DEFAULT NULL, state_province TEXT DEFAULT NULL, country TEXT DEFAULT NULL)
RETURNS Geometry AS $$
  from cartodb_services.tools import LegacyServiceManager
  from cartodb_services.here import HereMapsGeocoder

  plpy.execute("SELECT cdb_dataservices_server._get_logger_config()")
  service_manager = LegacyServiceManager('geocoder', username, orgname, GD)
  service_manager.assert_within_limits()

  try:
    geocoder = HereMapsGeocoder(service_manager.config.heremaps_app_id, service_manager.config.heremaps_app_code, service_manager.logger, service_manager.config.heremaps_service_params)
    coordinates = geocoder.geocode(searchtext=searchtext, city=city, state=state_province, country=country)
    if coordinates:
      service_manager.quota_service.increment_success_service_use()
      plan = plpy.prepare("SELECT ST_SetSRID(ST_MakePoint($1, $2), 4326); ", ["double precision", "double precision"])
      point = plpy.execute(plan, [coordinates[0], coordinates[1]], 1)[0]
      return point['st_setsrid']
    else:
      service_manager.quota_service.increment_empty_service_use()
      return None
  except BaseException as e:
    import sys
    service_manager.quota_service.increment_failed_service_use()
    service_manager.logger.error('Error trying to geocode street point using here maps', sys.exc_info(), data={"username": username, "orgname": orgname})
    raise Exception('Error trying to geocode street point using here maps')
  finally:
    service_manager.quota_service.increment_total_service_use()
$$ LANGUAGE plpythonu STABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION cdb_dataservices_server._cdb_google_geocode_street_point(username TEXT, orgname TEXT, searchtext TEXT, city TEXT DEFAULT NULL, state_province TEXT DEFAULT NULL, country TEXT DEFAULT NULL)
RETURNS Geometry AS $$
  from cartodb_services.tools import LegacyServiceManager
  from cartodb_services.google import GoogleMapsGeocoder

  plpy.execute("SELECT cdb_dataservices_server._get_logger_config()")
  service_manager = LegacyServiceManager('geocoder', username, orgname, GD)
  service_manager.assert_within_limits(quota=False)

  try:
    geocoder = GoogleMapsGeocoder(service_manager.config.google_client_id, service_manager.config.google_api_key, service_manager.logger)
    coordinates = geocoder.geocode(searchtext=searchtext, city=city, state=state_province, country=country)
    if coordinates:
      service_manager.quota_service.increment_success_service_use()
      plan = plpy.prepare("SELECT ST_SetSRID(ST_MakePoint($1, $2), 4326); ", ["double precision", "double precision"])
      point = plpy.execute(plan, [coordinates[0], coordinates[1]], 1)[0]
      return point['st_setsrid']
    else:
      service_manager.quota_service.increment_empty_service_use()
      return None
  except BaseException as e:
    import sys
    service_manager.quota_service.increment_failed_service_use()
    service_manager.logger.error('Error trying to geocode street point using google maps', sys.exc_info(), data={"username": username, "orgname": orgname})
    raise Exception('Error trying to geocode street point using google maps')
  finally:
    service_manager.quota_service.increment_total_service_use()
$$ LANGUAGE plpythonu STABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION cdb_dataservices_server._cdb_mapzen_geocode_street_point(username TEXT, orgname TEXT, searchtext TEXT, city TEXT DEFAULT NULL, state_province TEXT DEFAULT NULL, country TEXT DEFAULT NULL)
RETURNS Geometry AS $$
  from cartodb_services.tools import ServiceManager
  from cartodb_services.mapzen import MapzenGeocoder
  from cartodb_services.tools.country import country_to_iso3
  from cartodb_services.refactor.service.mapzen_geocoder_config import MapzenGeocoderConfigBuilder

  import cartodb_services
  cartodb_services.init(plpy, GD)

  service_manager = ServiceManager('geocoder', MapzenGeocoderConfigBuilder, username, orgname)
  service_manager.assert_within_limits()

  try:
    geocoder = MapzenGeocoder(service_manager.config.mapzen_api_key, service_manager.logger, service_manager.config.service_params)
    country_iso3 = None
    if country:
      country_iso3 = country_to_iso3(country)
    coordinates = geocoder.geocode(searchtext=searchtext, city=city,
                                   state_province=state_province,
                                   country=country_iso3, search_type='address')
    if coordinates:
      service_manager.quota_service.increment_success_service_use()
      plan = plpy.prepare("SELECT ST_SetSRID(ST_MakePoint($1, $2), 4326); ", ["double precision", "double precision"])
      point = plpy.execute(plan, [coordinates[0], coordinates[1]], 1)[0]
      return point['st_setsrid']
    else:
      service_manager.quota_service.increment_empty_service_use()
      return None
  except BaseException as e:
    import sys
    service_manager.quota_service.increment_failed_service_use()
    service_manager.logger.error('Error trying to geocode street point using mapzen', sys.exc_info(), data={"username": username, "orgname": orgname})
    raise Exception('Error trying to geocode street point using mapzen')
  finally:
    service_manager.quota_service.increment_total_service_use()
$$ LANGUAGE plpythonu STABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION cdb_dataservices_server._cdb_mapbox_geocode_street_point(username TEXT, orgname TEXT, searchtext TEXT, city TEXT DEFAULT NULL, state_province TEXT DEFAULT NULL, country TEXT DEFAULT NULL)
RETURNS Geometry AS $$
  from iso3166 import countries
  from cartodb_services.tools import ServiceManager
  from cartodb_services.mapbox import MapboxGeocoder
  from cartodb_services.refactor.service.mapbox_geocoder_config import MapboxGeocoderConfigBuilder

  import cartodb_services
  cartodb_services.init(plpy, GD)

  service_manager = ServiceManager('geocoder', MapboxGeocoderConfigBuilder, username, orgname, GD)
  service_manager.assert_within_limits()

  try:
    geocoder = MapboxGeocoder(service_manager.config.mapbox_api_key, service_manager.logger, service_manager.config.service_params)

    country_iso3166 = None
    if country:
      country_iso3166 = countries.get(country).alpha2.lower()

    coordinates = geocoder.geocode(searchtext=searchtext, city=city,
                                    state_province=state_province,
                                    country=country_iso3166)
    if coordinates:
      service_manager.quota_service.increment_success_service_use()
      plan = plpy.prepare("SELECT ST_SetSRID(ST_MakePoint($1, $2), 4326); ", ["double precision", "double precision"])
      point = plpy.execute(plan, [coordinates[0], coordinates[1]], 1)[0]
      return point['st_setsrid']
    else:
      service_manager.quota_service.increment_empty_service_use()
      return None
  except BaseException as e:
    import sys
    service_manager.quota_service.increment_failed_service_use()
    service_manager.logger.error('Error trying to geocode street point using mapbox', sys.exc_info(), data={"username": username, "orgname": orgname})
    raise Exception('Error trying to geocode street point using mapbox')
  finally:
    service_manager.quota_service.increment_total_service_use()
$$ LANGUAGE plpythonu STABLE PARALLEL RESTRICTED;
