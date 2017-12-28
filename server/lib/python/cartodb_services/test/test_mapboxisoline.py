import unittest
from mock import Mock
from cartodb_services.mapbox.isolines import MapboxIsolines
from cartodb_services.mapbox.matrix_client import DEFAULT_PROFILE
from cartodb_services.mapbox.matrix_client import MapboxMatrixClient
from cartodb_services.mapbox.routing import MapboxRouting
from cartodb_services.tools import Coordinate
from cartodb_services.tools.coordinates import (validate_coordinates,
                                                marshall_coordinates)

VALID_TOKEN = 'pk.eyJ1IjoiYWNhcmxvbiIsImEiOiJjamJuZjQ1Zjc0Ymt4Mnh0YmFrMmhtYnY4In0.gt9cw0VeKc3rM2mV5pcEmg'
VALID_ORIGIN = Coordinate(-73.989, 40.733)


class MapboxIsolinesTestCase(unittest.TestCase):

    def setUp(self):
        matrix_client = MapboxMatrixClient(token=VALID_TOKEN, logger=Mock())
        self.mapbox_isolines = MapboxIsolines(matrix_client, logger=Mock())

    def test_calculate_isochrone(self):
        time_range = 10 * 60  # 10 minutes
        solution = self.mapbox_isolines.calculate_isochrone(
            origin=VALID_ORIGIN,
            profile=DEFAULT_PROFILE,
            time_range=time_range)

        assert solution

    def test_calculate_isodistance(self):
        distance_range = 10000
        solution = self.mapbox_isolines.calculate_isodistance(
            origin=VALID_ORIGIN,
            profile=DEFAULT_PROFILE,
            distance_range=distance_range)

        assert solution
