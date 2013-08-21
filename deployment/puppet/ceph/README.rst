===========
puppet-ceph
===========

Copy right
==========

Copyright: (C) 2013 Mirantis. Licensed under the Apache 2.0 License.

About
=====

This is a Puppet module to install a Ceph cluster inside of OpenStack.
This module has been developed specifically to work with Fuel.

.. _Puppet: http://www.puppetlabs.com/
.. _Ceph: http://ceph.com/
.. _Fuel: http://fuel.mirantis.com

Status
======

Originally Developped/tested on Ubuntu GNU/Linux Precise, targetting the 
Cuttlefish Ceph release.

* Ubuntu 12.04.2 LTS
* Puppet 3.2.2
* Ceph 0.61.7

_Ubuntu support is currently broken but will be back soon_

Currently working on CentOS 6.4 with CEPH Cuttlefish.

* CentOS 6.4
* Puppet 2.7.19
* Ceph 0.61.8


Features
========

* Ceph package
* Ceph MONs
* Ceph OSDs
* Ceph MDS

============

Using
=====

To deploy a CEPH cluster you need at least one monitor and two OSD devices. If
you are deploying CEPH outside of Fuel, see the example/site.pp for the 
parameters necessary to adjust.

This module requires the puppet agents to have `pluginsync = true`.

Understanding example Puppet manifest:
===========================================================

  $mon_nodes = [
  'ceph-mon-1',
  ]

This parameter defines the nodes for which the monitor process will be 
installed. This should be one, three or more monitors. 
-----------------------------------------------------------

  $osd_nodes = [
  'ceph-osd-1',
  'ceph-osd-2',
  ]

This parameter defines the nodes for which the OSD process` will run. One OSD
will be created for each `$osd_volume` per `$osd_nodes`. There is a minimum
requirement of two OSD instances. 

-----------------------------------------------------------

  $mds_server = 'ceph-mds-01'

Uncomment this line if you want to install metadata server. Metadata is only
necessary for CephFS and should run on separate hardware from the other
OpenStack nodes.

-----------------------------------------------------------

  $osd_devices = [ 'vdb', 'vdc1' ]

This parameter defines which drive, partition or path will be used in Ceph
OSD on each OSD node. when referring to whole devices or partitions, 
/dev/<device> is not necessary 

-----------------------------------------------------------

  $ceph_pools = [ 'volumes', 'images' ]

This parameter defines the names of the ceph pools we want to pre-create.
By default `volumes` and `images` are necessary for the hooks to setup the
OpenStack hooks.

-----------------------------------------------------------

  node 'default' {
  ...
      }

This section configure components for all nodes of CEPH and OpenStack.

-----------------------------------------------------------

  class { 'ceph::deploy':
    auth_supported   => 'cephx',
    osd_journal_size => '2048',
    osd_mkfs_type    => 'xfs',

In this section you can change authentication type, journal size (in KB), type 
of filesystem.

After Deployment
================

There are several commands that we can run post cluster creation.

Verifying deployment
--------------------

You can issue `ceph -s` or `ceph health` (terse) to check the current status of the 
cluster. The output of `ceph -s` should include:

* `monmap`: this should contain the correct number of monitors
* `osdmap`: this should contain the correct number of osd instances (one per
 node per volume)

  root@fuel-ceph-02:~# ceph -s
  health HEALTH_OK
  monmap e1: 2 mons at {fuel-ceph-01=10.0.0.253:6789/0,fuel-ceph-02=10.0.0.252:6789/0}, election epoch 4, quorum 0,1 fuel-ceph-01,fuel-ceph-02
  osdmap e23: 4 osds: 4 up, 4 in
  pgmap v275: 448 pgs: 448 active+clean; 9518 bytes data, 141 MB used, 28486 MB / 28627 MB avail
  mdsmap e4: 1/1/1 up {0=fuel-ceph-02.local.try=up:active}

===Common issues===

`ceph -s` returned `health HEALTH_WARN`

  root@fuel-ceph-01:~# ceph -s
  health HEALTH_WARN 63 pgs peering; 54 pgs stuck inactive; 208 pgs stuck unclean; recovery 2/34 degraded (5.882%)
  ...

-----------------------------------------------------------

`ceph` commands return key errors

check the links in /root/ceph*.keyring there should be one for each admin, 
osd, and mon. If any are missing this could be the cause.

Try to run `ceph-deploy gatherkeys {mon-server-name}`. If this dosn't work then
there may have been an issue starting the cluster.

check to see running ceph processes `ps axu | grep ceph` if there is a python
process running for `ceph-authtool` then there is likely a problem with the
mon processes talking to each other. Check their network and firewall. the 
monitor defaults to a port 6789

-----------------------------------------------------------

missing ods instances

by default there should be one OSD instance per volume per OSD node listed in
in the configuration. If one or more of them is missing you might have a 
problem with the initialization of the disks. Properly working block devices
be mounted for  you.

common issues:
* the disk or volume is in use
* the disk partition didn't refresh in the kernel

-----------------------------------------------------------


Hacking into Fuel
=================

After installing onto a fuel cluster

CentOS
------
#. define your partitions. If you will re-define any partations you must 
 make sure they are exposed in the kernel before running the scripts see 
 `partx -a /dev/<device>` after `umount /boot`.

Installing
----------
#. copy fuel-pm:/etc/puppet/modules/* to {node}:/etc/puppet/modules
#. copy /etc/puppet/modules/ceph/examples/site.pp to /root/ceph.pp
#. edit for desired changes to $mon_nodes and $osd_nodes and `$osd_disks`
#. run puppet apply ceph.pp to all nodes _(ensure that `$ceph_nodes[-1]` is LAST)_

