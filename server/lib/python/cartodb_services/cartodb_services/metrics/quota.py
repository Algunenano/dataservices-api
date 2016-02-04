from user import UserMetricsService
from datetime import date


class QuotaService:
    """ Class to manage all the quota operation for
    the Geocoder SQL API Extension """

    def __init__(self, user_geocoder_config, redis_connection):
        self._user_geocoder_config = user_geocoder_config
        self._user_service = UserMetricsService(
            self._user_geocoder_config, redis_connection)

    def check_user_quota(self):
        """ Check if the current user quota surpasses the current quota """
        # We don't have quota check for google geocoder
        if self._user_geocoder_config.google_geocoder:
            return True

        user_quota = self._user_geocoder_config.geocoding_quota
        today = date.today()
        service_type = self._user_geocoder_config.service_type
        current_used = self._user_service.used_quota(service_type, today)
        soft_geocoding_limit = self._user_geocoder_config.soft_geocoding_limit

        if soft_geocoding_limit or current_used <= user_quota:
            return True
        else:
            return False

    def increment_success_geocoder_use(self, amount=1):
        self._user_service.increment_service_use(
            self._user_geocoder_config.service_type, "success_responses",
            amount=amount)

    def increment_empty_geocoder_use(self, amount=1):
        self._user_service.increment_service_use(
            self._user_geocoder_config.service_type, "empty_responses",
            amount=amount)

    def increment_failed_geocoder_use(self, amount=1):
        self._user_service.increment_service_use(
            self._user_geocoder_config.service_type, "fail_responses",
            amount=amount)

    def increment_total_geocoder_use(self, amount=1):
        self._user_service.increment_service_use(
            self._user_geocoder_config.service_type, "total_requests",
            amount=amount)
