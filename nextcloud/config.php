<?php
$CONFIG = array (
  'instanceid' => 'oc7y9l3kyvi9',
  'enable_previews' => false,
  'memcache.local' => '\OC\Memcache\APCu',
  'memcache.distributed' => '\OC\Memcache\Redis',
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => [
     'host' => 'redis',
     'port' => 6379,
     'timeout' => 0.0,
  ],
);

//  //Memcached alternative to redis
//  'memcache.local' => '\OC\Memcache\APCu',
//  'memcache.distributed' => '\OC\Memcache\Memcached',
//  'memcache.locking' => '\OC\Memcache\Memcached',
//  'memcached_servers' => [
//    [ 'memcached', 11211 ],
//  ],
