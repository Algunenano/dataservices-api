from dateutil.parser import parse as date_parse
from cartodb_services.refactor.service.utils import round_robin
from cartodb_services.tomtom.types import TOMTOM_ROUTING_APIKEY_ROUNDROBIN


class TomTomRoutingConfig(object):
    """
    Configuration needed to operate the TomTom directions service.
    """

    def __init__(self,
                 routing_quota,
                 soft_routing_limit,
                 monthly_quota,
                 period_end_date,
                 cost_per_hit,
                 log_path,
                 tomtom_api_keys,
                 username,
                 organization,
                 service_params,
                 GD):
        self._routing_quota = routing_quota
        self._soft_routing_limit = soft_routing_limit
        self._monthly_quota = monthly_quota
        self._period_end_date = period_end_date
        self._cost_per_hit = cost_per_hit
        self._log_path = log_path
        self._tomtom_api_keys = tomtom_api_keys
        self._username = username
        self._organization = organization
        self._service_params = service_params
        self._GD = GD

    @property
    def service_type(self):
        return 'routing_tomtom'

    @property
    def provider(self):
        return 'tomtom'

    @property
    def is_high_resolution(self):
        return True

    @property
    def routing_quota(self):
        return self._routing_quota

    @property
    def soft_limit(self):
        return self._soft_routing_limit

    @property
    def monthly_quota(self):
        return self._monthly_quota

    @property
    def period_end_date(self):
        return self._period_end_date

    @property
    def cost_per_hit(self):
        return self._cost_per_hit

    @property
    def log_path(self):
        return self._log_path

    @property
    def tomtom_api_key(self):
        return round_robin(self._tomtom_api_keys, self._GD,
                           TOMTOM_ROUTING_APIKEY_ROUNDROBIN)

    @property
    def username(self):
        return self._username

    @property
    def organization(self):
        return self._organization

    @property
    def service_params(self):
        return self._service_params


class TomTomRoutingConfigBuilder(object):

    def __init__(self, server_conf, user_conf, org_conf, username, orgname, GD):
        self._server_conf = server_conf
        self._user_conf = user_conf
        self._org_conf = org_conf
        self._username = username
        self._orgname = orgname
        self._GD = GD

    def get(self):
        tomtom_server_conf = self._server_conf.get('tomtom_conf')
        tomtom_api_keys = tomtom_server_conf['routing']['api_keys']
        monthly_quota = tomtom_server_conf['routing']['monthly_quota']
        tomtom_service_params = tomtom_server_conf['routing'].get('service', {})

        routing_quota = self._get_quota()
        soft_routing_limit = self._user_conf.get('soft_mapzen_routing_limit').lower() == 'true'
        cost_per_hit = 0
        period_end_date_str = self._org_conf.get('period_end_date') or self._user_conf.get('period_end_date')
        period_end_date = date_parse(period_end_date_str)

        logger_conf = self._server_conf.get('logger_conf')
        log_path = logger_conf.get('routing_log_path', None)

        return TomTomRoutingConfig(routing_quota,
                                   soft_routing_limit,
                                   monthly_quota,
                                   period_end_date,
                                   cost_per_hit,
                                   log_path,
                                   tomtom_api_keys,
                                   self._username,
                                   self._orgname,
                                   tomtom_service_params,
                                   self._GD)

    def _get_quota(self):
        routing_quota = self._org_conf.get('mapzen_routing_quota') or self._user_conf.get('mapzen_routing_quota')
        if routing_quota is '':
            return 0

        return int(routing_quota)
