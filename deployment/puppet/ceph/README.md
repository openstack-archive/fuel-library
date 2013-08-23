Mirantis Puppet module for Ceph
===============================

About
-----

This is a Puppet module to install a Ceph cluster inside of OpenStack. This
module has been developed specifically to work with Mirantis Fuel for
OpenStack.

* Puppet: http://www.puppetlabs.com/
* Ceph: http://ceph.com/
* Fuel: http://fuel.mirantis.com/

Status
------

Originally developped and tested on Ubuntu 12.04 LTS (Precise Pangolin),
targetting the Ceph 0.61 (Cuttlefish) release:

* Ubuntu 12.04.2 LTS
* Puppet 3.2.2
* Ceph 0.61.7

**Ubuntu support is currently broken but will be back soon**

Currently working on CentOS 6.4 with Ceph 0.61:

* CentOS 6.4
* Puppet 2.7.19
* Ceph 0.61.8

Known Issues
------------

**Glance**

There are currently issues with glance 2013.1.2 (grizzly) that cause ``glance 
image-create`` with ``--location`` to not function. see 
https://bugs.launchpad.net/glance/+bug/1215682 


Features
--------

* Ceph package
* Ceph Monitors
* Ceph OSDs
* Ceph MDS (slightly broken)
* Ceph Object Gateway (radosgw): coming soon

Using
-----

To deploy a Ceph cluster you need at least one monitor and two OSD devices. If
you are deploying Ceph outside of Fuel, see the example/site.pp for the
parameters that you will need to adjust.

This module requires the puppet agents to have ``pluginsync = true``.

Understanding the example Puppet manifest
-----------------------------------------

```puppet
$mon_nodes = [
  'ceph-mon-1',
]
```

This parameter defines the nodes for which the monitor process will be 
installed. This should be one, three or more monitors.

```puppet
$osd_nodes = [
  'ceph-osd-1',
  'ceph-osd-2',
]
```

This parameter defines the nodes for which the OSD process` will run. One OSD
will be created for each ``$osd_volume`` per ``$osd_nodes``. There is a minimum
requirement of two OSD instances. 

```puppet
$mds_server = 'ceph-mds-01'
```

Uncomment this line if you want to install metadata server. Metadata is only
necessary for CephFS and should run on separate hardware from the other
OpenStack nodes.

```puppet
$osd_devices = [ 'vdb', 'vdc1' ]
```

This parameter defines which drive, partition or path will be used in Ceph OSD
on each OSD node. When referring to whole devices or partitions, the /dev/ prefix
is not necessary.

```puppet
$ceph_pools = [ 'volumes', 'images' ]
```

This parameter defines the names of the ceph pools we want to pre-create. By
default, ``volumes`` and ``images`` are necessary to setup the OpenStack hooks.

```puppet
node 'default' {
  ...
}
```

This section configures components for all nodes of Ceph and OpenStack.

```puppet
class { 'ceph::deploy':
    auth_supported   => 'cephx',
    osd_journal_size => '2048',
    osd_mkfs_type    => 'xfs',
}
```

In this section you can change authentication type, journal size (in KB), type
of filesystem.

Verifying the deployment
------------------------

You can issue ``ceph -s`` or ``ceph health`` (terse) to check the current
status of the cluster. The output of ``ceph -s`` should include:

* ``monmap``: this should contain the correct number of monitors
* ``osdmap``: this should contain the correct number of osd instances (one per
  node per volume)

```
   root@fuel-ceph-02:~# ceph -s
   health HEALTH_OK
   monmap e1: 2 mons at {fuel-ceph-01=10.0.0.253:6789/0,fuel-ceph-02=10.0.0.252:6789/0}, election epoch 4, quorum 0,1 fuel-ceph-01,fuel-ceph-02
   osdmap e23: 4 osds: 4 up, 4 in
   pgmap v275: 448 pgs: 448 active+clean; 9518 bytes data, 141 MB used, 28486 MB / 28627 MB avail
   mdsmap e4: 1/1/1 up {0=fuel-ceph-02.local.try=up:active}
```

Here are some errors that may be reported.

``ceph -s`` returned ``health HEALTH_WARN``:

```
   root@fuel-ceph-01:~# ceph -s
   health HEALTH_WARN 63 pgs peering; 54 pgs stuck inactive; 208 pgs stuck unclean; recovery 2/34 degraded (5.882%)
   ...
```

``ceph`` commands return key errors:

```
	[root@controller-13 ~]# ceph -s
	2013-08-22 00:06:19.513437 7f79eedea760 -1 monclient(hunting): ERROR: missing keyring, cannot use cephx for authentication
	2013-08-22 00:06:19.513466 7f79eedea760 -1 ceph_tool_common_init failed.
  
```

Check the links in ``/root/ceph\*.keyring``. There should be one for each of
admin, osd, and mon. If any are missing this could be the cause.

Try to run ``ceph-deploy gatherkeys {mon-server-name}``. If this dosn't work
then there may have been an issue starting the cluster.

Check to see running ceph processes ``ps axu | grep ceph``. If there is a
python process running for ``ceph-authtool`` then there is likely a problem
with the MON processes talking to each other. Check their network and firewall.
The monitor defaults to a port 6789

Missing OSD instances
---------------------

By default there should be one OSD instance per volume per OSD node listed in
in the configuration. If one or more of them is missing you might have a
problem with the initialization of the disks. Properly working block devices be
mounted for  you.

Common issues:

* the disk or volume is in use
* the disk partition didn't refresh in the kernel

Check the osd tree:

```
	#ceph osd tree
	
	# id    weight  type name       up/down reweight
	-1      6       root default
	-2      2               host controller-1
	0       1                       osd.0   up      1
	3       1                       osd.3   up      1
	-3      2               host controller-2
	1       1                       osd.1   up      1
	4       1                       osd.4   up      1
	-4      2               host controller-3
	2       1                       osd.2   up      1
	5       1                       osd.5   up      1
```

Ceph pools
----------

By default we create two pools ``image``, and ``volumes``, there should also be
defaults of ``data``, ``metadata``, and ``rdb``. ``ceph osd lspools`` can show the 
current pools:

	# ceph osd lspools
	0 data,1 metadata,2 rbd,3 images,4 volumes,

Testing openstack
-----------------


### Glance

To test Glance, upload an image to Glance to see if it is saved in Ceph:

```shell
source ~/openrc
glance image-create --name cirros --container-format bare \
  --disk-format qcow2 --is-public yes --location \
  https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img
```

**Note: ``--location`` is currently broken in glance see known issues above use
below instead**

```
source ~/openrc
wget https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img
glance image-create --name cirros --container-format bare \
  --disk-format qcow2 --is-public yes < cirros-0.3.0-x86_64-disk.img
```

This will return somthing like:

```
   +------------------+--------------------------------------+
   | Property         | Value                                |
   +------------------+--------------------------------------+
   | checksum         | None                                 |
   | container_format | bare                                 |
   | created_at       | 2013-08-22T19:54:28                  |
   | deleted          | False                                |
   | deleted_at       | None                                 |
   | disk_format      | qcow2                                |
   | id               | f52fb13e-29cf-4a2f-8ccf-a170954907b8 |
   | is_public        | True                                 |
   | min_disk         | 0                                    |
   | min_ram          | 0                                    |
   | name             | cirros                               |
   | owner            | baa3187b7df94d9ea5a8a14008fa62f5     |
   | protected        | False                                |
   | size             | 0                                    |
   | status           | active                               |
   | updated_at       | 2013-08-22T19:54:30                  |
   +------------------+--------------------------------------+
```

Then check rdb:

```shell
rdb ls images
```

```shell
rados -p images df
```

Hacking into Fuel
-----------------

After installing onto a fuel cluster

1. Define your partitions. If you will re-define any partations you must make
sure they are exposed in the kernel before running the scripts see ``partx -a
/dev/<device>`` after ``umount /boot``.

2. Copy ``fuel-pm:/etc/puppet/modules/*`` to ``{node}:/etc/puppet/modules``
3. Copy ``/etc/puppet/modules/ceph/examples/site.pp`` to ``/root/ceph.pp``.
4. Edit ceph.pp for desired changes to ``$mon_nodes``, ``$osd_nodes``, and ``$osd_disks``.
5. Run ``puppet apply ceph.pp`` on each node **except** ``$ceph_nodes[-1]``,
then run the same command on that last node.

Copyright and License
---------------------

Copyright: (C) 2013 [Mirantis](https://www.mirantis.com/) Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

