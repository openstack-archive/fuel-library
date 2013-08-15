===========
puppet-ceph
===========

About
=====

This is a Puppet module to install a Ceph cluster.

.. _Puppet: http://www.puppetlabs.com/
.. _Ceph: http://ceph.com/

Status
======

Developped/tested on Ubuntu GNU/Linux Precise, targetting the Cuttlefish Ceph release.

* Ubuntu 12.04.2 LTS
* Puppet 3.2.2
* Ceph 0.61.7

Features
========

* Ceph package ✓

* Ceph MONs ✓

* Ceph OSDs ✓

* Ceph MDS ✓

============

Using
=====

To deploy CEPH cluster need at least two nodes, and any number of hard drives or partitions.

This module requires the puppet agents to have `pluginsync = true`.

Understanding Puppet manifest:
===========================================================

      $nodes = [
      'fuel-ceph-01',
      'fuel-ceph-02',
      ]

This parameter defines nodes for CEPH cluster.
Important notice! The last node is the admin node to deploy CEPH cluster. The last node deploy the least!

-----------------------------------------------------------

      $mds_server = 'fuel-ceph-01'

Uncomment this line if you want to install metadata server.

-----------------------------------------------------------

      $osd_devices = [ 'vdb', 'vdc' ]

This parameter defines which drive or partition will be used in CEPH cluster on each node. Don`t need to setting full path `/dev/vdb`.

-----------------------------------------------------------

      $pools = [ 'volumes', 'images' ]

Determine pools for Glance = `images` and Cinder = `volumes`.

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

In this section you can change authentication type, journal size (in KB), type of filesystem.

Testing
=======

First we need to determine how many nodes we will use in the cluster. Set the right amount in `$nodes` with FQDN.
Start puppet agent on first node from `$nodes`. When all nodes are deployed, start deploy on master node.
When the deployment is completed, you can check it on any node:

  root@fuel-ceph-01:~# ceph -s
  health HEALTH_WARN 63 pgs peering; 54 pgs stuck inactive; 208 pgs stuck unclean; recovery 2/34 degraded (5.882%)
  monmap e1: 2 mons at {fuel-ceph-01=10.0.0.253:6789/0,fuel-ceph-02=10.0.0.252:6789/0}, election epoch 4, quorum 0,1 fuel-ceph-01,fuel-ceph-02
  osdmap e23: 4 osds: 4 up, 4 in
  pgmap v57: 448 pgs: 172 active, 213 active+clean, 63 peering; 8116 bytes data, 138 MB used, 28489 MB / 28627 MB avail; 0B/s rd, 494B/s wr, 0op/s; 2/34 degraded (5.882%)
  mdsmap e3: 1/1/1 up {0=fuel-ceph-02.local.try=up:creating}


If u got `health HEALTH_WARN` dont warry, we need some time to stabilize cluster.

Check it again:

  root@fuel-ceph-02:~# ceph -s
  health HEALTH_OK
  monmap e1: 2 mons at {fuel-ceph-01=10.0.0.253:6789/0,fuel-ceph-02=10.0.0.252:6789/0}, election epoch 4, quorum 0,1 fuel-ceph-01,fuel-ceph-02
  osdmap e23: 4 osds: 4 up, 4 in
  pgmap v275: 448 pgs: 448 active+clean; 9518 bytes data, 141 MB used, 28486 MB / 28627 MB avail
  mdsmap e4: 1/1/1 up {0=fuel-ceph-02.local.try=up:active}

Cluster working. And everything nice!

After that start deployment on any node of OpenStack.
