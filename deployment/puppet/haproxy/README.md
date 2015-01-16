#haproxy

[![Build Status](https://travis-ci.org/puppetlabs/puppetlabs-haproxy.svg?branch=master)](https://travis-ci.org/puppetlabs/puppetlabs-haproxy)

####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with haproxy](#setup)
    * [Beginning with haproxy](#beginning-with-haproxy)
4. [Usage - Configuration options and additional functionality](#usage)
    * [Configuring haproxy options](#configuring-haproxy-options)
    * [Configuring an HAProxy daemon listener](#configuring-haproxy-daemon-listener)
    * [Configuring HAProxy load-balanced member nodes](#configuring-haproxy-loadbalanced-member-nodes)
    * [Configuring a load balancer with exported resources](#configuring-a-load-balancer-with-exported-resources)
    * [Classes and Defined Types](#classes-and-defined-types)
        * [Class: haproxy](#class-haproxy)
        * [Defined Type: haproxy::balancermember](#defined-type-haproxybalancermember)
        * [Defined Type: haproxy::backend](#defined-type-haproxybackend)
        * [Defined type: haproxy::frontend](#defined-type-haproxyfrontend)
        * [Defined type: haproxy::listen](#defined-type-haproxylisten)
        * [Defined Type: haproxy::userlist](#define-type-haproxyuserlist)
        * [Defined Type: haproxy::peers](#define-type-haproxypeers)
        * [Defined Type: haproxy::peer](#define-type-haproxypeer)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Public classes and defined types](#public-classes-and-defined-types)
    * [Private classes and defined types](#private-classes-and-defined-types)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

##Overview

The haproxy module provides the ability to install, configure, and manage HAProxy.

##Module Description

HAProxy is a daemon for load-balancing and proxying TCP and HTTP-based services.
This module configures proxy servers and manages the configuration of backend member servers.

##Setup

###Beginning with haproxy

The quickest way to get up and running using the haproxy module is to install and configure a basic HAProxy server that is listening on port 8140 and balanced against two nodes.

```puppet
node 'haproxy-server' {
  class { 'haproxy': }
  haproxy::listen { 'puppet00':
    collect_exported => false,
    ipaddress        => $::ipaddress,
    ports            => '8140',
  }
  haproxy::balancermember { 'master00':
    listening_service => 'puppet00',
    server_names      => 'master00.example.com',
    ipaddresses       => '10.0.0.10',
    ports             => '8140',
    options           => 'check',
  }
  haproxy::balancermember { 'master01':
    listening_service => 'puppet00',
    server_names      => 'master01.example.com',
    ipaddresses       => '10.0.0.11',
    ports             => '8140',
    options           => 'check',
  }
}
```

##Usage

###Configuring haproxy options

The main [`haproxy` class](#class-haproxy) has many options for configuring your HAProxy server.

```puppet
class { 'haproxy':
  global_options   => {
    'log'     => "${::ipaddress} local0",
    'chroot'  => '/var/lib/haproxy',
    'pidfile' => '/var/run/haproxy.pid',
    'maxconn' => '4000',
    'user'    => 'haproxy',
    'group'   => 'haproxy',
    'daemon'  => '',
    'stats'   => 'socket /var/lib/haproxy/stats',
  },
  defaults_options => {
    'log'     => 'global',
    'stats'   => 'enable',
    'option'  => 'redispatch',
    'retries' => '3',
    'timeout' => [
      'http-request 10s',
      'queue 1m',
      'connect 10s',
      'client 1m',
      'server 1m',
      'check 10s',
    ],
    'maxconn' => '8000',
  },
}
```

###Configuring HAProxy daemon listener


To export the resource for a balancermember and collect it on a single HAProxy load balancer server:

```puppet
haproxy::listen { 'puppet00':
  ipaddress => $::ipaddress,
  ports     => '18140',
  mode      => 'tcp',
  options   => {
    'option'  => [
      'tcplog',
      'ssl-hello-chk',
    ],
    'balance' => 'roundrobin',
  },
}
```
###Configuring multi-network daemon listener

One might have more advanced needs for the listen block, then use the `$bind` parameter:

```puppet
haproxy::listen { 'puppet00':
  mode    => 'tcp',
  options => {
    'option'  => [
      'tcplog',
      'ssl-hello-chk',
    ],
    'balance' => 'roundrobin',
  },
  bind    => {
    '10.0.0.1:443'             => ['ssl', 'crt', 'puppetlabs.com'],
    '168.12.12.12:80'          => [],
    '192.168.122.42:8000-8100' => ['ssl', 'crt', 'puppetlabs.com'],
    ':8443,:8444'              => ['ssl', 'crt', 'internal.puppetlabs.com']
  },
}
```
Note: `$ports` or `$ipaddress` and `$bind` are mutually exclusive

###Configuring HAProxy load-balanced member nodes

First, export the resource for a balancer member.

```puppet
@@haproxy::balancermember { 'haproxy':
  listening_service => 'puppet00',
  ports             => '8140',
  server_names      => $::hostname,
  ipaddresses       => $::ipaddress,
  options           => 'check',
}
```

Then, collect the resource on a load balancer.

```puppet
Haproxy::Balancermember <<| listening_service == 'puppet00' |>>
```

Then, create the resource for multiple balancer members at once (this assumes a single-pass installation of HAProxy without requiring a first pass to export the resources, and is intended for situations where you know the members in advance).

```puppet
haproxy::balancermember { 'haproxy':
  listening_service => 'puppet00',
  ports             => '8140',
  server_names      => ['server01', 'server02'],
  ipaddresses       => ['192.168.56.200', '192.168.56.201'],
  options           => 'check',
}
```
###Configuring a load balancer with exported resources

Install and configure an HAProxy server listening on port 8140 and balanced against all collected nodes. This HAProxy uses storeconfigs to collect and realize balancermember servers on a load balancer server.

```puppet
node 'haproxy-server' {
  class { 'haproxy': }
  haproxy::listen { 'puppet00':
    ipaddress => $::ipaddress,
    ports     => '8140',
  }
}

node /^master\d+/ {
  @@haproxy::balancermember { $::fqdn:
    listening_service => 'puppet00',
    server_names      => $::hostname,
    ipaddresses       => $::ipaddress,
    ports             => '8140',
    options           => 'check',
  }
}
```

The resulting HAProxy server will automatically collect configurations from backend servers. The backend nodes will export their HAProxy configurations to the puppet master which will then distribute them to the HAProxy server.

###Classes and Defined Types

####Class: `haproxy`

This is the main class of the module, guiding the installation and configuration of at least one HAProxy server.

**Parameters:**

#####`custom_fragment`
Allows arbitrary HAProxy configuration to be passed through to support additional configuration not otherwise available via parameters. Also allows arbitrary HAPRoxy configuration to short-circuit defined resources, such as `haproxy::listen`. Accepts a string (e.g. output from the template() function). Defaults to 'undef'.

#####`defaults_options`
All the default haproxy options, displayed in a hash. If you want to specify more than one option (i.e. multiple timeout or stats options), pass those options as an array and you will get a line for each of them in the resulting haproxy.cfg file.

#####`global_options`
All the haproxy global options, displayed in a hash. If you want to specify more than one option (i.e. multiple timeout or stats options), pass those options as an array and you will get a line for each of them in the resulting haproxy.cfg file.

#####`package_ensure`
Determines whether the HAProxy package should be installed or uninstalled. Defaults to 'present'.

#####`package_name`
Sets the HAProxy package name. Defaults to 'haproxy'.

#####`restart_command`
Specifies the command to use when restarting the service upon config changes.  Passed directly as the restart parameter to the service resource.  Defaults to 'undef', i.e. whatever the service default is.

#####`service_ensure`
Determines whether the HAProxy service should be running & enabled at boot, or stopped and disabled at boot. Defaults to 'running'.

#####`service_manage`
Specifies whether the HAProxy service state should be managed by Puppet. Defaults to 'true'.

####Defined Type: `haproxy::balancermember`

This type will set up a balancermember inside a listening or backend service configuration block in /etc/haproxy/haproxy.cfg on the load balancer. Currently, it has the ability to specify the instance name, ip address, port, and whether or not it is a backup.

Automatic discovery of balancermember nodes may be implemented by exporting the balancermember resource for all HAProxy balancer member servers and then collecting them on the main HAProxy load balancer.

**Parameters:**

#####`define_cookies`
Determines whether 'cookie SERVERID' stickiness options are added. Defaults to 'false'.

#####`ensure`
Determines whether the balancermember should be present or absent. Defaults to 'present'.

#####`ipaddresses`
Specifies the IP address used to contact the balancer member server. Can be an array. If this parameter is specified as an array it must be the same length as the [`server\_names`](#server_names) parameter's array. A balancermember is created for each pair of addresses. These pairs will be multiplied, and additional balancermembers created, based on the number of `ports` specified.

#####`listening_service`
Sets the HAProxy service's instance name (or the title of the `haproxy::listen` resource). This must match a declared `haproxy::listen` resource.

#####`name`
Specifies the title of the resource. The `name` is arbitrary and only utilized in the concat fragment name.

#####`options`
An array of options to be specified after the server declaration in the listening service's configuration block.

#####`ports`
Sets the ports on which the balancer member will accept connections from the load balancer. If ports are specified, it must be an array. If you use an array in `server\_names` and `ipaddresses`, the number of ports specified will multiply the number of balancermembers formed from the IP address and server name pairs. If no port is specified, the balancermember will receive the traffic on the same port the frontend receive it (Very useful if used with a frontend with multiple bind ports).

#####`server_names`
Sets the name of the balancermember server in the listening service's configuration block. Defaults to the hostname. Can be an array. If this parameter is specified as an array, it must be the same length as the [`ipaddresses`](#ipaddresses) parameter's array. A balancermember is created for each pair of `server\_names` and `ipaddresses` in the array.hese pairs will be multiplied, and additional balancermembers created, based on the number of `ports` specified.

####Defined Type: `haproxy::backend`

This type sets up a backend service configuration block inside the haproxy.cfg file on an HAProxy load balancer. Each backend service needs one or more load balancer member servers (declared with the [`haproxy::balancermember`](#defined-type-balancermember) defined type).

Using storeconfigs, you can export the `haproxy::balancermember` resources on all load balancer member servers and collect them on a single HAProxy load balancer server.

**Parameters**

#####`name`
Sets the backend service's name. Generally, it will be the namevar of the defined resource type. This value appears right after the 'backend' statement in haproxy.cfg

#####`options`
A hash of options that are inserted into the backend service configuration block.

#####`collect_exported`
Enables exported resources from `haproxy::balancermember` to be collected, serving as a form of autodiscovery. Displays as a Boolean and defaults to 'true'.

The 'true' value means exported balancermember resources, for the case when every balancermember node exports itself, will be collected. Whereas, 'false' means the existing declared balancermember resources will be relied on; this is meant for cases when you know the full set of balancermembers in advance and use `haproxy::balancermember` with array arguments, allowing you to deploy everything in a single run.

#####Example

To export the resource for a backend service member,

```puppet
haproxy::backend { 'puppet00':
  options => {
    'option'  => [
      'tcplog',
      'ssl-hello-chk',
    ],
    'balance' => 'roundrobin',
  },
}
```

####Defined type: `haproxy::frontend`

This type sets up a frontend service configuration block in haproxy.cfg. The HAProxy daemon uses the directives in the .cfg file to determine which ports/IPs to listen on and route traffic on those ports/IPs to specified balancermembers.

**Parameters**

#####`bind_options`
Lists an array of options to be specified after the bind declaration in the bind's configuration block. **Deprecated**: This parameter is being deprecated in favor of $bind

#####`bind`
A hash of listening addresses/ports, and a list of parameters that make up the listen service's `bind` lines. This is the most flexible way to configure listening services in a frontend or listen directive. See http://cbonte.github.io/haproxy-dconv/configuration-1.5.html#4.2-bind for details.

The hash keys represent the listening address and port, such as `192.168.122.1:80`, `10.1.1.1:8900-9000`, `:80,:8080` or `/var/run/haproxy-frontend.sock` and the key's value is an array of bind options for that listening address, such as `[ 'ssl', 'crt /etc/ssl/puppetlabs.com.crt', 'no-sslv3' ]`. Example:

```puppet
bind => {
  '168.12.12.12:80'                     => [],
  '192.168.1.10:8080,192.168.1.10:8081' => [],
  '10.0.0.1:443-453'                    => ['ssl', 'crt', 'puppetlabs.com'],
  ':8443,:8444'                         => ['ssl', 'crt', 'internal.puppetlabs.com'],
  '/var/run/haproxy-frontend.sock'      => [ 'user root', 'mode 600', 'accept-proxy' ],
}
```

#####`ipaddress`
Specifies the IP address the proxy binds to. No value, '\*', and '0.0.0.0' mean that the proxy listens to all valid addresses on the system.

#####`mode`
Sets the mode of operation for the frontend service. Valid values are 'undef', 'tcp', 'http', and 'health'.

#####`name`
Sets the frontend service's name. Generally, it will be the namevar of the defined resource type. This value appears right after the 'fronted' statement in haproxy.cfg.

#####`options`
A hash of options that are inserted into the frontend service configuration block.

#####`ports`
Sets the ports to listen on for the address specified in `ipaddress`. Accepts a single, comma-separated string or an array of strings, which may be ports or hyphenated port ranges.

#####Example

To route traffic from port 8140 to all balancermembers added to a backend with the title 'puppet_backend00',

```puppet
haproxy::frontend { 'puppet00':
  ipaddress     => $::ipaddress,
  ports         => '18140',
  mode          => 'tcp',
  bind_options  => 'accept-proxy',
  options       => {
    'option'          => [ 'default_backend', 'puppet_backend00'],
    'timeout client'  => '30',
    'balance'         => 'roundrobin'
    'option'          => [
      'tcplog',
      'accept-invalid-http-request',
    ],
  },
}
```

####Defined type: `haproxy::listen`

This type sets up a listening service configuration block inside the haproxy.cfg file on an HAProxy load balancer. Each listening service configuration needs one or more load balancer member server (declared with the [`haproxy::balancermember`](#defined-type-balancermember) defined type).

Using storeconfigs, you can export the `haproxy::balancermember` resources on all load balancer member servers and  collect them on a single HAProxy load balancer server.

**Parameters:**

#####`bind_options`
Sets the options to be specified after the bind declaration in the listening service's configuration block. Displays as an array. **Deprecated**: This parameter is being deprecated in favor of $bind

#####`bind`
A hash of listening addresses/ports, and a list of parameters that make up the listen service's `bind` lines. This is the most flexible way to configure listening services in a frontend or listen directive. See http://cbonte.github.io/haproxy-dconv/configuration-1.5.html#4.2-bind for details.

The hash keys represent the listening address and port, such as `192.168.122.1:80`, `10.1.1.1:8900-9000`, `:80,:8080` or `/var/run/haproxy-frontend.sock` and the key's value is an array of bind options for that listening address, such as `[ 'ssl', 'crt /etc/ssl/puppetlabs.com.crt', 'no-sslv3' ]`. Example:

```puppet
bind => {
  '168.12.12.12:80'                     => [],
  '192.168.1.10:8080,192.168.1.10:8081' => [],
  '10.0.0.1:443-453'                    => ['ssl', 'crt', 'puppetlabs.com'],
  ':8443,:8444'                         => ['ssl', 'crt', 'internal.puppetlabs.com'],
  '/var/run/haproxy-frontend.sock'      => [ 'user root', 'mode 600', 'accept-proxy' ],
}
```

#####`collect_exported`
Enables exported resources from `haproxy::balancermember` to be collected, serving as a form of autodiscovery. Displays as a Boolean and defaults to 'true'.

The 'true' value means exported balancermember resources, for the case when every balancermember node exports itself, will be collected. Whereas, 'false' means the existing declared balancermember resources will be relied on; this is meant for cases when you know the full set of balancermembers in advance and use `haproxy::balancermember` with array arguments, allowing you to deploy everything in a single run.

#####`ipaddress`
Specifies the IP address the proxy binds to. No value, '\*', and '0.0.0.0' mean that the proxy listens to all valid addresses on the system.

#####`mode`
Specifies the mode of operation for the listening service. Valid values are 'undef', 'tcp', 'http', and 'health'.

#####`name`
Sets the listening service's name. Generally, it will be the namevar of the defined resource type. This value appears right after the 'listen' statement in haproxy.cfg.

#####`options`
A hash of options that are inserted into the listening service configuration block.

#####`ports`
Sets the ports to listen on for the address specified in `ipaddress`. Accepts a single, comma-separated string or an array of strings, which may be ports or hyphenated port ranges.

####Defined Type: `haproxy::userlist`

This type sets up a [userlist configuration block](http://cbonte.github.io/haproxy-dconv/configuration-1.4.html#3.4) inside the haproxy.cfg file on an HAProxy load balancer.

**Parameters:**

#####`name`
Sets the userlist's name. Generally it will be the namevar of the defined resource type. This value appears right after the 'userlist' statement in haproxy.cfg


#####`users`
An array of users in the userlist. See http://cbonte.github.io/haproxy-dconv/configuration-1.4.html#3.4-user

#####`groups`
An array of groups in the userlist. See http://cbonte.github.io/haproxy-dconv/configuration-1.4.html#3.4-group


####Defined Type: `haproxy::peers`

This type will set up a peers entry in /etc/haproxy/haproxy.cfg on the load balancer. This setting is required to share the current state of HAproxy with other HAproxy in High available configurations.

** parameters **

#####`name`
Sets the peers' name. Generally it will be the namevar of the defined resource type. This value appears right after the 'peers' statement in haproxy.cfg


####Defined Type: `haproxy::peer`

This type will set up a peer entry inside the peers configuration block in /etc/haproxy/haproxy.cfg on the load balancer. Currently, it has the ability to specify the instance name, ip address, ports and server_names.

Automatic discovery of peer nodes may be implemented by exporting the peer resource for all HAProxy balancer servers that are configured in the same HA block and then collecting them on all load balancers.

**Parameters:**

#####`peers_name`
Specifies the peer in which this load balancer needs to be added.

#####`server_names`
Sets the name of the peer server in the peers configuration block. Defaults to the hostname. Can be an array. If this parameter is specified as an array, it must be the same length as the [`ipaddresses`](#ipaddresses) parameter's array. A peer is created for each pair of `server\_names` and `ipaddresses` in the array.

####`ensure`
Whether to add or remove the peer. Defaults to 'present'. Valid values are 'present' and 'absent'.

#####`ipaddresses`
Specifies the IP address used to contact the peer member server. Can be an array. If this parameter is specified as an array it must be the same length as the [`server\_names`](#server_names) parameter's array. A peer is created for each pair of address and server_name.

#####`ports`
Sets the port on which the peer is going to share the state.


##Reference

###Public classes and defined types

* Class `haproxy`: Main configuration class
* Define `haproxy::listen`: Creates a listen entry in the config
* Define `haproxy::frontend`: Creates a frontend entry in the config
* Define `haproxy::backend`: Creates a backend entry in the config
* Define `haproxy::balancermember`: Creates server entries for listen or backend blocks.
* Define `haproxy::userlist`: Creates a userlist entry in the config
* Define `haproxy::peers`: Creates a peers entry in the config
* Define `haproxy::peer`: Creates server entries for ha configuration inside peers.

###Private classes and defined types

* Class `haproxy::params`: Per-operatingsystem defaults.
* Class `haproxy::install`: Installs packages.
* Class `haproxy::config`: Configures haproxy.cfg.
* Class `haproxy::service`: Manages service.
* Define `haproxy::balancermember::collect_exported`: Collects exported balancermembers
* Define `haproxy::peer::collect_exported`: Collects exported peers

##Limitations

RedHat and Debian family OSes are officially supported. Tested and built on Ubuntu and CentOS.

##Development

Puppet Labs modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can’t access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

You can read the complete module contribution guide [on the Puppet Labs wiki.](http://projects.puppetlabs.com/projects/module-site/wiki/Module_contributing)
