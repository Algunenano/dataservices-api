import user_service
from datetime import date

class QuotaService:
    """ Class to manage all the quota operation for the Geocoder SQL API Extension """

    def __init__(self, user_id, transaction_id, redis_connection):
        self._user_service = user_service.UserService(user_id, redis_connection)
        self.transaction_id = transaction_id

    def check_user_quota(self):
        """ Check if the current user quota surpasses the current quota """
        # TODO We need to add the hard/soft limit flag for the geocoder
        user_quota = self.user_service.user_quota()
        today = date.today()
        current_used = self.user_service.used_quota_month(today.year, today.month)
        soft_geocoder_limit = self.user_service.soft_geocoder_limit()

        return True if soft_geocoder_limit or (current_used + 1) < user_quota else False

    def increment_geocoder_use(self, amount=1):
        today = date.today()
        self.user_service.increment_geocoder_use(today.year, today.month, self.transaction_id)

    @property
    def user_service(self):
        return self._user_service