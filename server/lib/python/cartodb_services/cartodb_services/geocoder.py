#!/usr/local/bin/python
# -*- coding: utf-8 -*-

from tools import QuotaExceededException, Logger
from collections import namedtuple
import json


def compose_address(street, city=None, state=None, country=None):
    return ', '.join(filter(None, [street, city, state, country]))


def run_street_point_geocoder(plpy, GD, geocoder, service_manager, username, orgname, searches):
    plpy.execute("SELECT cdb_dataservices_server._get_logger_config()")
    logger_config = GD["logger_config"]

    logger = Logger(logger_config)

    try:
        service_manager.assert_within_limits(quota=False)
        geocode_results = geocoder.bulk_geocode(searches=searches)
        if geocode_results:
            results = []
            for result in geocode_results:
                if result[1] and len(result[1]) == 2:
                    plan = plpy.prepare("SELECT ST_SetSRID(ST_MakePoint($1, $2), 4326) as the_geom; ", ["double precision", "double precision"])
                    point = plpy.execute(plan, result[1], 1)[0]
                    results.append([result[0], point['the_geom'], None])
                else:
                    results.append([result[0], None, None])
            service_manager.quota_service.increment_success_service_use(len(results))
            return results
        else:
            service_manager.quota_service.increment_empty_service_use(len(searches))
            return []
    except QuotaExceededException as qe:
        service_manager.quota_service.increment_failed_service_use(len(searches))
        return []
    except BaseException as e:
        import sys
        service_manager.quota_service.increment_failed_service_use()
        service_manager.logger.error('Error trying to bulk geocode street point', sys.exc_info(), data={"username": username, "orgname": orgname})
        raise Exception('Error trying to bulk geocode street')
    finally:
        service_manager.quota_service.increment_total_service_use()


StreetGeocoderSearch = namedtuple('StreetGeocoderSearch', 'id address city state country')


class StreetPointBulkGeocoder:
    """
    Classes extending StreetPointBulkGeocoder should implement:
        * _batch_geocode(street_geocoder_searches)
        * MAX_BATCH_SIZE

    If they want to provide an alternative serial (for small batches):
        * _should_use_batch(street_geocoder_searches)
        * _serial_geocode(street_geocoder_searches)
    """

    SEARCH_KEYS = ['id', 'address', 'city', 'state', 'country']

    def bulk_geocode(self, searches):
        """
        :param searches: array of StreetGeocoderSearch
        :return: array of tuples with three elements:
            * id
            * latitude and longitude (array of two elements)
            * empty array (future use: metadata)
        """
        try:
            decoded_searches = json.loads(searches)
        except Exception as e:
            self._logger.error('General error', exception=e)
            raise e

        street_geocoder_searches = []
        for search in decoded_searches:
            search_id, address, city, state, country = \
                [search.get(k, None) for k in self.SEARCH_KEYS]
            street_geocoder_searches.append(
                StreetGeocoderSearch(search_id, address, city, state, country))

        if len(street_geocoder_searches) > self.MAX_BATCH_SIZE:
            raise Exception("Batch size can't be larger than {}".format(self.MAX_BATCH_SIZE))
        if self._should_use_batch(street_geocoder_searches):
            self._logger.debug('--> Batch geocode')
            return self._batch_geocode(street_geocoder_searches)
        else:
            self._logger.debug('--> Serial geocode')
            return self._serial_geocode(street_geocoder_searches)

    def _batch_geocode(self, street_geocoder_searches):
        raise NotImplementedError('Subclasses must implement _batch_geocode')

    def _serial_geocode(self, street_geocoder_searches):
        raise NotImplementedError('Subclasses must implement _serial_geocode')

    def _should_use_batch(self, street_geocoder_searches):
        return True


