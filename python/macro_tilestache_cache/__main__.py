import sys, json, os

from redis import Redis

TILESTACHE_CACHE_REDIS_CONFIG = {
    "host": u'localhost',
    "port": 6379,
    "db":0
}

def flush(md5):
    cache = Redis(**TILESTACHE_CACHE_REDIS_CONFIG)
    count = 0
    # tilestache_cache_key_pattern = 'tilestache/%s*' % (md5)
    tilestache_cache_key_pattern = 'tilestache/*'
    for key in cache.scan_iter(tilestache_cache_key_pattern):
        cache.delete(key)
        count += 1
    print('%s keys has been unset.' % (count))

usage = '''
USAGE:
    main.py method md5
'''
if __name__ == '__main__':
    num_args = len(sys.argv)
    if num_args == 3:
        if sys.argv[1] == 'flush':
            flush(sys.argv[2])
    else:
        print(usage)
        exit(1)