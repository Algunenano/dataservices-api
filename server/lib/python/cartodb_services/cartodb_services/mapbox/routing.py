'''
Python client for the Mapbox Routing service.
'''

import json
import requests
from cartodb_services.metrics import Traceable
from cartodb_services.tools import PolyLine
from cartodb_services.tools.coordinates import (validate_coordinates,
                                                marshall_coordinates)
from cartodb_services.mapbox.exceptions import ServiceException

ACCESS_TOKEN = 'pk.eyJ1IjoiYWNhcmxvbiIsImEiOiJjamJuZjQ1Zjc0Ymt4Mnh0YmFrMmhtYnY4In0.gt9cw0VeKc3rM2mV5pcEmg'

BASEURI = ('https://api.mapbox.com/directions/v5/mapbox/{profile}/'
           '{coordinates}'
           '?access_token={token}'
           '&overview={overview}')

NUM_WAYPOINTS_MIN = 2  # https://www.mapbox.com/api-documentation/#directions
NUM_WAYPOINTS_MAX = 25  # https://www.mapbox.com/api-documentation/#directions

PROFILE_DRIVING_TRAFFIC = 'driving-traffic'
PROFILE_DRIVING = 'driving'
PROFILE_CYCLING = 'cycling'
PROFILE_WALKING = 'walking'
DEFAULT_PROFILE = PROFILE_DRIVING

DEFAULT_OVERVIEW = 'full'

VALID_PROFILES = [PROFILE_DRIVING_TRAFFIC,
                  PROFILE_DRIVING,
                  PROFILE_CYCLING,
                  PROFILE_WALKING]

ENTRY_ROUTES = 'routes'
ENTRY_GEOMETRY = 'geometry'
ENTRY_DURATION = 'duration'
ENTRY_DISTANCE = 'distance'


class MapboxRouting(Traceable):
    '''
    Python wrapper for the Mapbox Routing service.
    '''

    def __init__(self, token=ACCESS_TOKEN):
        self._token = token

    def _uri(self, coordinates, profile=DEFAULT_PROFILE,
             overview=DEFAULT_OVERVIEW):
        return BASEURI.format(profile=profile, coordinates=coordinates,
                              token=self._token, overview=overview)

    def _validate_profile(self, profile):
        if profile not in VALID_PROFILES:
            raise ValueError('{profile} is not a valid profile. '
                             'Valid profiles are: {valid_profiles}'.format(
                                 profile=profile,
                                 valid_profiles=', '.join(
                                     [x for x in VALID_PROFILES])))

    def _parse_routing_response(self, response):
        json_response = json.loads(response)
        route = json_response[ENTRY_ROUTES][0]  # Force the first route

        geometry = PolyLine().decode(route[ENTRY_GEOMETRY])
        distance = route[ENTRY_DISTANCE]
        duration = route[ENTRY_DURATION]

        return MapboxRoutingResponse(geometry, distance, duration)

    def directions(self, waypoints, profile=DEFAULT_PROFILE):
        self._validate_profile(profile)
        validate_coordinates(waypoints, NUM_WAYPOINTS_MIN, NUM_WAYPOINTS_MAX)

        coordinates = marshall_coordinates(waypoints)

        uri = self._uri(coordinates, profile)
        response = requests.get(uri)

        if response.status_code == requests.codes.ok:
            return self._parse_routing_response(response.text)
        elif response.status_code == requests.codes.bad_request:
            return MapboxRoutingResponse(None, None, None)
        else:
            raise ServiceException(response.status_code, response.content)


class MapboxRoutingResponse:

    def __init__(self, shape, length, duration):
        self._shape = shape
        self._length = length
        self._duration = duration

    @property
    def shape(self):
        return self._shape

    @property
    def length(self):
        return self._length

    @property
    def duration(self):
        return self._duration
