from redis.sentinel import Sentinel
from redis import StrictRedis
import json
import plpy
from cartodb_services.config import DBConfig


class RedisConnectionFactory:

    @classmethod
    def get_metadata_connection(cls, username):
        cache_key = "redis_connection_{0}_metadata".format(username)
        if cache_key in plpy.GD:
            connection = plpy.GD[cache_key]
        else:
            metadata_config = RedisDBConfig('redis_metadata_config')
            connection = RedisConnection(metadata_config).redis_connection()
        return connection

    @classmethod
    def get_metrics_connection(cls, username):
        cache_key = "redis_connection_{0}_metrics".format(username)
        if cache_key in plpy.GD:
            connection = plpy.GD[cache_key]
        else:
            metrics_config = RedisDBConfig('redis_metrics_config')
            connection = RedisConnection(metrics_config).redis_connection()
        return connection

class RedisConnection:

    def __init__(self, config):
        self._config = config

    def redis_connection(self):
        return self.__create_redis_connection()

    def __create_redis_connection(self):
        if self._config.sentinel_id:
            sentinel = Sentinel([(self._config.host,
                                  self._config.port)],
                                socket_timeout=self._config.timeout)
            return sentinel.master_for(self._config.sentinel_id,
                                       socket_timeout=self._config.timeout,
                                       db=self._config.db,
                                       retry_on_timeout=True)
        else:
            conn = StrictRedis(host=self._config.host, port=self._config.port,
                               db=self._config.db, retry_on_timeout=True,
                               socket_timeout=self._config.timeout)
            return conn


class RedisDBConfig:

    DEFAULT_USER_DB = 5
    DEFAULT_TIMEOUT = 1.5  # seconds

    def __init__(self, key):
        self._db_config = DBConfig()
        return self._build(key)

    def _build(self, key):
        conf = self._db_config.get(key)
        if conf is None:
            raise "There is no redis configuration defined"
        else:
            params = json.loads(conf)
            self._host = params['redis_host']
            self._port = params['redis_port']

            if "timeout" in params:
                self._timeout = params['timeout']
            else:
                self._timeout = self.DEFAULT_TIMEOUT

            if "redis_db" in params:
                self._db = params['redis_db']
            else:
                self._db = self.DEFAULT_USER_DB

            if "sentinel_master_id" in params:
                self._sentinel_id = params["sentinel_master_id"]
            else:
                self._sentinel_id = None

    def __str__(self):
        return "Host: {0}, Port: {1}, Sentinel id: {2}, DB: {3}, " \
               "Timeout: {4}".format(self.host, self.port, self.sentinel_id,
                                     self.db, self.timeout)

    @property
    def host(self):
        return self._host

    @property
    def port(self):
        return self._port

    @property
    def timeout(self):
        return self._timeout

    @property
    def db(self):
        return self._db

    @property
    def sentinel_id(self):
        return self._sentinel_id
