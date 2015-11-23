# twemproxy

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with twemproxy](#setup)
    * [Beginning with twemproxy](#beginning-with-twemproxy)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

It's a puppet module for installing and configuring Twemproxy - memcached proxy
created in Twitter. Tested for:

* Ubuntu trusty

Should work for most linux distros.

## Module Description

This module install, configure and run twemproxy. You can do any of these tasks
separately or combine them for installing twemproxy from scratch.


## Setup

### Beginning with twemproxy

I believe that it should be enough to call

```puppet
class { 'twemproxy':
  clients_array => $memcache_array,
}
```
with array of `<memcache node address>:<port>:<weight>` values to start using
twemproxy and force it to do something useful

## Usage

Most of the work can be done through main twemproxy class, so you can just call
`::twemproxy` with options you need to use all functionality this module covers

###I need just setup twemproxy and create a pool with servers, what should I do?

```puppet
class { 'twemproxy:
  clients_array => ['10.10.10.10:11211:1', '10.10.10.20:11211:1'],
}
```

###I need just manage already existing config

```puppet
twemproxy::pool { 'mypool':
  listen_address       => '127.0.0.1',
  listen_port          => '22122',
  timeout              => '400',
  redis                => false,
  redis_auth           => false,
  server_connections   => 1,
  server_retry_timeout => 3000,
  clients_array        => ['10.10.10.10:11211:1', '10.10.10.20:11211:1'],
}
```

## Reference

### Classes

* twemproxy: main class, include all others.
* twemproxy::install: handles the package.
* twemproxy::config: handles the daemon configuration file.
* twemproxy::service: handles the service.
* twemproxy::params: handles most of the parameters.

### Defined types

* twemproxy::listen: defines config part for twemproxy pool itself.
* twemproxy::member: defines config part for memcache members in pool.
* twemproxy::pool: combine previous two defines to one pool config.

### Parameters

Next parameter available in main twempxory class:

####`package_manage`
Tells whether we should manage twemproxy package. Valid options: 'true' or
'false'. Default option: 'true'.

####`package_name`
Tells package name we should manage.

####`package_ensure`
Set what we should do with package. Valid options: 'present' or 'absent'.
Default value: 'present'.

####`service_manage`
Tells if we should manage twemproxy service. Valid options: 'true' or 'false'.
Default option: 'true'

####`service_name`
Set service name for twemproxy.

####`service_ensure`
Tells if we should install or remove service. Valid options: 'running' or
'stopped'. Default option: 'running'

####`service_enable`
Tells if we should enable service on system start. Valid options: 'true' or
'false'. Default option: 'true'

####`listen_address`
Address twemproxy will listen on. Default value: '127.0.0.1'

####`listen_port`
Port twemproxy will listen on. Default value: 22122

####`timeout`
The timeout value in msec that twemproxy will wait for to establish a connection
o the server or receive a response from a server. Set it to false if you want
to wait indefinitely. Default value: 400

####`backlog`
The TCP backlog argument. Default value: 1024

####`preconnect`
A boolean value that controls if twemproxy should preconnect to all the servers
in this pool on process start. Default value: 'false'

####`redis`
A boolean value that controls if a server pool speaks redis or memcached
protocol. Default value: 'false'

####`redis_auth`
Authenticate to the Redis server on connect. Default value: 'false'

####`redis_db`
The DB number to use on the pool servers. Defaults to false

####`server_connections`
The maximum number of connections that can be opened to each server. Default
value: 1

####`auto_eject_hosts`
A boolean value that controls if server should be ejected temporarily when it
fails consecutively `server_failure_limit` times. Default value: 'false'

####`server_retry_timeout`
The timeout value in msec to wait for before retrying on a temporarily ejected
server, when `auto_eject_host` is set to true. Default value: 30000

####`server_failure_limit`
The number of consecutive failures on a server that would lead to it being
temporarily ejected when `auto_eject_host` is set to true. Default value: 2

####`client_address`
Address of client for twemproxy.

####`client_port`
Port which client will bind to. Default value: 11211

####`client_weight`
Weight of client. Default value: 1

####`clients_array`
Array with client conections. You can consider it like array with different
clients pointed as '`client_address`:`client_port`:`client_weight`'. Example
of use:

```puppet
[
  '10.10.10.10:11211:1',
  '10.10.20.20:11211:1',
  '10.10.30.30:11211:2',
]
```

## Limitations

This module was tested only on Ububtu trusty, but should probably work on
other platforms too.

## Development

This module is completely free, so I would appreciate any pull-requests to it
or its redistribution.

## Contributors

- Stanislaw Bogatkin
