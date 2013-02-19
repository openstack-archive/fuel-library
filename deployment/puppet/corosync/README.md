Puppet Labs module for Corosync
============================

These manfisests are derived from puppetlabs-corosync modules.



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

Configuring cluster properties
------------------------------

* Configure quorum policy

```puppet
cs_property { 'no-quorum-policy':
  ensure => present,
  value  => 'ignore',
}
```puppet

Configuring primitives
------------------------

The resources that Corosync will manage can be referred to as a primitive.
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

*Make Corosync manage and monitor the state of Nginx using a custom OCF agent*

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


*Make Corosync manage and monitor the state of Apache using a LSB agent*

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

Configuring resource locations
--------------------------------

You can pacemaker resource locations

In this case you have to options according to pacemaker rules.

1) Specify node score by use of `node_score` and `node` parameters
2) Specify the hash of rules containing all the pacemaker location parameters


```puppet 
cs_location { 'l_11':
 'name'=>"l_11",:rules=>[
          {'score'=>"INFINITY",'boolean'=>'',
            'expressions'=>[
              {'attribute'=>"#uname",'operation'=>'ne','value'=>'ubuntu-1'}
                ],
            'date_expressions' => [
              {'date_spec'=>{'hours'=>"10", 'weeks'=>"5"}, 'operation'=>"date_spec", 'start'=>"", 'end'=>""},
              {'date_spec'=>{'weeks'=>"5"}, 'operation'=>"date_spec", 'start'=>"", 'end'=>""}
                ]
           }
        ],
         'primitive'=> 'master_bar', ensure=>present
}

Configuring shadow CIB
----------------------

If you want the bunch of parameters be applied at once, use cs_shadow and `shadow`
parameter to specify the shadow CIB to be created. In this case puppet will create
CIB with corresponding name and commit it after all changes are applied.

You can also specify `isempty` parameter for creation of empty shadow CIB. 
Be really careful with it. Don't blame me if you ruined your cluster by use of
this parameter.   

Dependencies
------------

Tested and built on Ubuntu 12.04 with 1.4.2 of Corosync is validated to function.

Notes
-----

This module doesn't abstract away everything about managing Corosync but makes setup
and automation easier.  Things that are currently outstanding...

 * Needs a lot more tests.
 * There is already a handful of bugs that need to be worked out.
 * Doesn't have any way to configure STONITH
 * Plus a other things since Corosync and Pacemaker do a lot.

We suggest you at least go read the [Clusters from Scratch](http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html-single/Clusters_from_Scratch) document
from Cluster Labs.  It will help you out a lot when understanding how all the pieces
fall together a point you in the right direction when Corosync fails unexpectedly.

A simple but complete manifest example can be found on [Cody Herriges' Github](https://github.com/ody/ha-demo), plus
there are more incomplete examples spread across the [Puppet Labs Github](https://github.com/puppetlabs).

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
