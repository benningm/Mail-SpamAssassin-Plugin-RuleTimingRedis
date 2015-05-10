# NAME

Mail::SpamAssassin::Plugin::RuleTimingRedis - collect SA rule timings in redis

# VERSION

version 1.000

# DESCRIPTION

RuleTimingRedis is a plugin for spamassassin which gathers and stores performance data of processed spamassassin rules in a redis server.

# CONFIGURATION

To load the plugin put an loadplugin line into init.pre:


```
  loadplugin Mail::SpamAssassin::Plugin::RuleTimingRedis
```
If the RuleTimingRedis.pm is not in perls @INC you need to specify the path:


```
  loadplugin Mail::SpamAssassin::Plugin::RuleTimingRedis <path-to>/RuleTimingRedis.pm
```
If your redis server is not listening on 127.0.0.1:6379 configure the address in local.cf:


```
  timing_redis_server 192.168.0.10:6379
```
Then restart amavisd.

After the first mail was processed the keys for the processed rules should appear in redis:


```
  $ redis-cli
  redis 127.0.0.1:6379> KEYS 'sa-timing.*'
     1) "sa-timing.__DRUGS_SLEEP3.count"
     2) "sa-timing.__MAIL_LINK.count"
     3) "sa-timing.__CGATE_RCVD.count"
  ...
```
# PARAMETERS

The plugin has the following configuration options:

## timing_redis_server (default: '127.0.0.1:6379')

Address and port of the redis server.
 
## timing_redis_prefix (default: 'sa-timing.')

Prefix to used for the keys in redis.

## timing_redis_precision (default: 1000000)

Since redis uses integers the floating point value is multiplied by this factor before storing in redis.

## timing_redis_debug (default: 0)

Turn on/off debug on the Redis connection.

# AUTHOR

Markus Benning <ich@markusbenning.de>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning.

This is free software, licensed under:


```
  The Apache License, Version 2.0, January 2004
```
