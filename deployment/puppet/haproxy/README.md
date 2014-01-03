PuppetLabs Module for haproxy
=============================

HAProxy is an HA proxying daemon for load-balancing to clustered services. It
can proxy TCP directly, or other kinds of traffic such as HTTP.

Basic Usage
-----------

This haproxy uses storeconfigs to collect and realize balancer member servers
on a load balancer server. Currently Redhat family OSes are supported.

*To install and configure HAProxy server listening on port 80*

```puppet
node 'haproxy-server' {
  class { 'haproxy': }
  haproxy::listen { 'puppet00':
    ipaddress => $::ipaddress,
    ports     => '8140',
  }
}
```

*To add backend loadbalance members*

```puppet
node 'webserver01' {
  @@haproxy::balancermember { $fqdn:
    listening_service => 'puppet00',
    server_names      => $::hostname,
    ipaddresses       => $::ipaddress,
    ports             => '8140',
    options           => 'check'
  }
}
```

Configuring haproxy options
---------------------------

The base `haproxy` class can accept two parameters which will configure basic
behaviour of the haproxy server daemon:

- `global_options` to configure the `global` section in `haproxy.cfg`
- `defaults_options` to configure the `defaults` section in `haproxy.cfg`

Configuring haproxy daemon listener
-----------------------------------

One `haproxy::listen` defined resource should be defined for each HAProxy loadbalanced set of backend servers. The title of the `haproxy::listen` resource is the key to which balancer members will be proxied to. The `ipaddress` field should be the public ip address which the loadbalancer will be contacted on. The `ports` attribute can accept an array or comma-separated list of ports which should be proxied to the `haproxy::balancermember` nodes.

Configuring haproxy daemon frontend
-----------------------------------

One `haproxy::frontend` defined resource should be defined for each HAProxy front end you wish to set up. The `ipaddress` field should be the public ip address which the loadbalancer will be contacted on. The `ports` attribute can accept an array or comma-separated list of ports which should be proxied to the `haproxy::backend` resources.

Configuring haproxy daemon backend
----------------------------------

One `haproxy::backend` defined resource should be defined for each HAProxy loadbalanced set of backend servers. The title of the `haproxy::backend` resource is the key to which balancer members will be proxied to. Note that an `haproxy::listen` resource and `haproxy::backend` resource *can* have the same name, and any balancermembers exported to that name will show up in both places. This is likely to have unsatisfactory results, but there's nothing preventing this from happening.

Configuring haproxy loadbalanced member nodes
---------------------------------------------

The `haproxy::balancermember` defined resource should be exported from each node
which is serving loadbalanced traffic. the `listening_service` attribute will
associate it with `haproxy::listen` directives on the haproxy node.
`ipaddresses` and `ports` will be assigned to the member to be contacted on. If an array of `ipaddresses` and `server_names` are provided then they will be added to the config in lock-step.

Dependencies
------------

Tested and built on Ubuntu and CentOS

Copyright and License
---------------------

Copyright (C) 2012 [Puppet Labs](https://www.puppetlabs.com/) Inc

Puppet Labs can be contacted at: info@puppetlabs.com

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
