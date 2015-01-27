Fuel module for Pacemaker
=========================

These manfisests are derived from puppetlabs-corosync modules v0.1.0.

Basic usage
-----------

Configuring primitives
------------------------

The resources that Pacemaker will manage can be referred to as a primitive.
These are things like virtual IPs or services like drbd, nginx, and apache.



*To assign a VIP to a network interface to be used by Nginx*

```puppet
cs_resource { 'nginx_vip':
  primitive_class => 'ocf',
  primitive_type  => 'IPaddr2',
  provided_by     => 'heartbeat',
  parameters      => { 'ip' => '172.16.210.100', 'cidr_netmask' => '24' },
  operations      => { 'monitor' => { 'interval' => '10s' } },
}
```

*Make Pacemaker manage and monitor the state of Nginx using a custom OCF agent*

```puppet
cs_resource { 'nginx_service':
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


*Make Pacemaker manage and monitor the state of Apache using a LSB agent*

```puppet
cs_resource { 'nginx_service':
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

*You can also specify multi-state resource such as clone or master

```puppet
cs_resource {'nginx_service':
primitive_class => 'lsb',
  provided_by     => 'heartbeat',
  operations      => {
    'monitor' => { 'interval' => '10s', 'timeout' => '30s' },
    'start'   => { 'interval' => '0', 'timeout' => '30s', 'on-fail' => 'restart' }
  },
  require         => Cs_primitive['apache2_vip'],
  multistate_hash => {'type'=>'clone','name'=>'nginx_clone'
  ms_metadata => {'interleave'=>'true'}
  }
}
```

Dependencies
------------

Tested and built on Ubuntu 12.04 with 1.4.2 of Corosync is validated to function.

Notes
-----

Contributors
------------

  * Mirantis Inc. 
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
