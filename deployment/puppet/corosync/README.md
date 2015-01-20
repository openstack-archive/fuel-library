Puppet Labs module for Corosync
============================

[![Build Status](https://travis-ci.org/puppetlabs/puppetlabs-corosync.png?branch=master)](https://travis-ci.org/puppetlabs/puppetlabs-corosync)

Corosync is a cluster stack written as a reimplementation of all the core
functionalities required by openais.  Meant to provide 100% correct operation
during failures or partitionable networks.

Most famous for being the cluster stack used by Pacemaker to support n-code
clusters that can respond to node and resource level events.

Basic usage
-----------

*To install and configure Corosync*

```puppet
class { 'corosync':
  enable_secauth    => true,
  authkey           => '/var/lib/puppet/ssl/certs/ca.pem',
  bind_address      => $ipaddress,
  multicast_address => '239.1.1.2',
}
```

*To enable Pacemaker*

```puppet
corosync::service { 'pacemaker':
  version => '0',
}
```

Configuring primitives
------------------------

The resources that Corosync will manage can be referred to as a primitive.
These are things like virtual IPs or services like drbd, nginx, and apache.

*To assign a VIP to a network interface to be used by Nginx*

```puppet
cs_primitive { 'nginx_vip':
  primitive_class => 'ocf',
  primitive_type  => 'IPaddr2',
  provided_by     => 'heartbeat',
  parameters      => { 'ip' => '172.16.210.100', 'cidr_netmask' => '24' },
  operations      => { 'monitor' => { 'interval' => '10s' } },
}
```

*Make Corosync manage and monitor the state of Nginx using a custom OCF agent*

```puppet
cs_primitive { 'nginx_service':
  primitive_class => 'ocf',
  primitive_type  => 'nginx_fixed',
  provided_by     => 'pacemaker',
  operations      => {
    'monitor' => { 'interval' => '10s', 'timeout' => '30s' },
    'start'   => { 'interval' => '0', 'timeout' => '30s', 'on-fail' => 'restart' }
  },
  require         => Cs_primitive['nginx_vip'],
}
```

*Make Corosync manage and monitor the state of Apache using a LSB agent*

```puppet
cs_primitive { 'nginx_service':
  primitive_class => 'lsb',
  primitive_type  => 'apache2',
  provided_by     => 'heartbeat',
  operations      => {
    'monitor' => { 'interval' => '10s', 'timeout' => '30s' },
    'start'   => { 'interval' => '0', 'timeout' => '30s', 'on-fail' => 'restart' }
  },
  require         => Cs_primitive['apache2_vip'],
}
```

Note: Operations with the same names should be declared as an Array. Example:
```puppet
cs_primitive { 'pgsql_service':
  primitive_class => 'ocf',
  primitive_type  => 'pgsql',
  provided_by     => 'heartbeat',
  operations      => {
    'monitor' => [
      { 'interval' => '10s', 'timeout' => '30s' },
      { 'interval' => '5s', 'timeout' => '30s', 'role' => 'Master' },
    ],
    'start'   => { 'interval' => '0', 'timeout' => '30s', 'on-fail' => 'restart' }
  },
}
```


Configuring locations
-----------------------

Locations determine on which nodes primitive resources run. 

```puppet
cs_location { 'nginx_service_location':
  primitive => 'nginx_service',
  node_name => 'hostname',
  score     => 'INFINITY'
}
```
Configuring colocations
-----------------------

Colocations keep primitives together.  Meaning if a vip moves to web02 from web01
because web01 just hit the dirt it will drag the nginx service with it.

```puppet
cs_colocation { 'vip_with_service':
  primitives => [ 'nginx_vip', 'nginx_service' ],
}
```

Configuring migration or state order
------------------------------------

Colocation defines that a set of primitives must live together on the same node
but order definitions will define the order of which each primitive is started.  If
Nginx is configured to listen only on our vip we definitely want the vip to be
migrated to a new node before nginx comes up or the migration will fail.

```puppet
cs_order { 'vip_before_service':
  first   => 'nginx_vip',
  second  => 'nginx_service',
  require => Cs_colocation['vip_with_service'],
}
```

Corosync Properties
------------------
A few gloabal settings can be changed with the "cs_property" section.


Disable STONITH if required.
```puppet
cs_property { 'stonith-enabled' :
  value   => 'false',
}
```

Change quorum policy 
```
cs_property { 'no-quorum-policy' :
  value   => 'ignore',
}
```


Dependencies
------------

Tested and built on Debian 6 using backports so version 1.4.2 of Corosync is validated
to function.

Notes
-----

This module doesn't abstract away everything about managing Corosync but makes setup
and automation easier.  Things that are currently outstanding...

 * Needs a lot more tests.
 * There is already a handful of bugs that need to be worked out.
 * Plus a other things since Corosync and Pacemaker do a lot.

We suggest you at least go read the [Clusters from Scratch](http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html-single/Clusters_from_Scratch) document
from Cluster Labs.  It will help you out a lot when understanding how all the pieces
fall together a point you in the right direction when Corosync fails unexpectedly.

A simple but complete manifest example can be found on [Cody Herriges' Github](https://github.com/ody/ha-demo), plus
there are more incomplete examples spread across the [Puppet Labs Github](https://github.com/puppetlabs).

Contributors
------------

  * [See Puppet Labs Github](https://github.com/puppetlabs/puppetlabs-corosync/graphs/contributors)

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
