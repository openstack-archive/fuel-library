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

Currently working with Ceph 0.61:

Developed and tested with:

* CentOS 6.4, Ubuntu 12.04
* Puppet 2.7.19
* Ceph 0.61.8

Known Issues
------------

**Glance**

There are currently issues with glance 2013.1.2 (grizzly) that cause ``glance
image-create`` with ``--location`` to not function. see
https://bugs.launchpad.net/glance/+bug/1215682 

**RadosGW, Keystone and Python 2.6**

RadosGW (RGW) will work with Keystone token_formats UUID or PKI. While RGW
perfers using PKI tokens. Python 2.6 distributions currently may not work
correctly with the PKI tokens. As such, keystone integration will defalt to
UUID, but you can adjust as desired see ```rgw_use_pki``` option.

Features
--------

* Ceph package
* Ceph Monitors
* Ceph OSDs
* Ceph MDS (present, but un-supported)
* Ceph Object Gateway (radosgw)
* * Openstack Keystone integration


Using
-----

To deploy a Ceph cluster you need at least one monitor and two OSD devices. If
you are deploying Ceph outside of Fuel, see the example/site.pp for the
parameters that you will need to adjust.

This module requires the puppet agents to have ``pluginsync = true``.

Understanding the example Puppet manifest
-----------------------------------------

This section should be re-written.

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
python process running for ``ceph-create-keys`` then there is likely a problem
with the MON processes talking to each other.
* Check each mon's network and firewall. The monitor defaults to a port 6789
* If public_network is defined in ceph.conf, mon_host and DNS names **MUST**
  be inside the public_network or ceph-deploy wont create mon's

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
defaults of ``data``, ``metadata``, and ``rbd``. ``ceph osd lspools`` can show
the current pools:

	# ceph osd lspools
	0 data,1 metadata,2 rbd,3 images,4 volumes,

Testing Openstack
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

Then check rbd:

```shell
rbd ls images
```

```shell
rados -p images df
```

### Cinder

To test cinder, we will create a small volume and see if it was saved in cinder

```shell
source openrc
cinder create 1
```

This will instruct cinder to create a 1 GiB volume, it should respond with
something similar to:

```
+---------------------+--------------------------------------+
|       Property      |                Value                 |
+---------------------+--------------------------------------+
|     attachments     |                  []                  |
|  availability_zone  |                 nova                 |
|       bootable      |                false                 |
|      created_at     |      2013-08-30T00:01:39.011655      |
| display_description |                 None                 |
|     display_name    |                 None                 |
|          id         | 78bf2750-e99c-4c52-b5ca-09764af367b5 |
|       metadata      |                  {}                  |
|         size        |                  1                   |
|     snapshot_id     |                 None                 |
|     source_volid    |                 None                 |
|        status       |               creating               |
|     volume_type     |                 None                 |
+---------------------+--------------------------------------+
```

Then we can check the status of the image using its ``id`` using
``cinder show <id>``

```
cinder show 78bf2750-e99c-4c52-b5ca-09764af367b5
+------------------------------+--------------------------------------+
|           Property           |                Value                 |
+------------------------------+--------------------------------------+
|         attachments          |                  []                  |
|      availability_zone       |                 nova                 |
|           bootable           |                false                 |
|          created_at          |      2013-08-30T00:01:39.000000      |
|     display_description      |                 None                 |
|         display_name         |                 None                 |
|              id              | 78bf2750-e99c-4c52-b5ca-09764af367b5 |
|           metadata           |                  {}                  |
|    os-vol-host-attr:host     |       controller-19.domain.tld       |
| os-vol-tenant-attr:tenant_id |   b11a96140e8e4522b81b0b58db6874b0   |
|             size             |                  1                   |
|         snapshot_id          |                 None                 |
|         source_volid         |                 None                 |
|            status            |              available               |
|         volume_type          |                 None                 |
+------------------------------+--------------------------------------+
``` 

Since the image is ``status`` ``available`` it should have been created in
ceph. we can check this with ``rbd ls volumes``

```shell
rbd ls volumes
volume-78bf2750-e99c-4c52-b5ca-09764af367b5
```

### Rados GW

First confirm that the cluster is ```HEALTH_OK``` using ```ceph -s``` or
```ceph health detail```. If the cluster isn't healthy most of these tests
will not function.

#### Checking on the Rados GW service.

***Note: RedHat distros: mod_fastcgi's /etc/httpd/conf.d/fastcgi.conf must
have ```FastCgiWrapper Off``` or rados calls will return 500 errors***

Rados relies on the service ```radosgw``` (Debian) ```ceph-radosgw``` (RHEL)
running and creating a socket for the webserver's script service to talk to.
If the radosgw service is not running, or not staying running then we need to
inspect it closer.

the service script for radosgw might exit 0 and not start the service, the
easy way to test this is to simply ```service ceph-radosgw restart``` if the
service script can not stop the service, it wasn't running in the first place.

We can also check to see if the rados service might be running by 
```ps axu | grep radosgw```, but this might also show the webserver script
server processes as well.

most commands from ```radosgw-admin``` will work wether or not the ```radosgw```
service is running.

#### swift testing

##### Simple authentication for RadosGW


create a new user

```shell
radosgw-admin user create --uid=test --display-name="bob" --email="bob@mail.ru"
```

```
{ "user_id": "test",
  "display_name": "bob",
  "email": "bob@mail.ru",
  "suspended": 0,
  "max_buckets": 1000,
  "auid": 0,
  "subusers": [],
  "keys": [
        { "user": "test",
          "access_key": "CVMC8OX9EMBRE2F5GA8C",
          "secret_key": "P3H4Ilv8Lhx0srz8ALO\/7udwkJd6raIz11s71FIV"}],
  "swift_keys": [],
  "caps": []}
```

swift auth works with subusers, in that from openstack this would be
tennant:user so we need to mimic the same

```shell
radosgw-admin subuser create --uid=test --subuser=test:swift --access=full
```

```
{ "user_id": "test",
  "display_name": "bob",
  "email": "bob@mail.ru",
  "suspended": 0,
  "max_buckets": 1000,
  "auid": 0,
  "subusers": [
        { "id": "test:swift",
          "permissions": "full-control"}],
  "keys": [
        { "user": "test",
          "access_key": "CVMC8OX9EMBRE2F5GA8C",
          "secret_key": "P3H4Ilv8Lhx0srz8ALO\/7udwkJd6raIz11s71FIV"}],
  "swift_keys": [],
  "caps": []}
```

Generate the secret key. 
___Note that ```--gen-secred``` is required in (at least) cuttlefish and newer.___

```shell
radosgw-admin key create --subuser=test:swift --key-type=swift --gen-secret
```

```
{ "user_id": "test",
  "display_name": "bob",
  "email": "bob@mail.ru",
  "suspended": 0,
  "max_buckets": 1000,
  "auid": 0,
  "subusers": [
        { "id": "test:swift",
          "permissions": "full-control"}],
  "keys": [
        { "user": "test",
          "access_key": "CVMC8OX9EMBRE2F5GA8C",
          "secret_key": "P3H4Ilv8Lhx0srz8ALO\/7udwkJd6raIz11s71FIV"}],
  "swift_keys": [
        { "user": "test:swift",
          "secret_key": "hLyMvpVNPez7lBqFlLjcefsZnU0qlCezyE2IDRsp"}],
  "caps": []}
```

some test commands

```shell
swift -A http://localhost:6780/auth/1.0 -U test:swift -K "eRYvzUr6vubg93dMRMk60RWYiGdJGvDk3lnwi4cl" post test
swift -A http://localhost:6780/auth/1.0 -U test:swift -K "eRYvzUr6vubg93dMRMk60RWYiGdJGvDk3lnwi4cl" upload test myfile
swift -A http://localhost:6780/auth/1.0 -U test:swift -K "eRYvzUr6vubg93dMRMk60RWYiGdJGvDk3lnwi4cl" list test
```

##### Keystone intergration

We will start with a simple test, we should be able to use the keystone openrc
credentials and start using the swift client as if we where actually using
swift.

```shell
source openrc
swift post test
swift list test
```

```
test
```


Clean up ceph to re-run
=======================

some times it is necessary to re-set the ceph-cluster rather than rebuilding
everything from cratch

set ``all`` to contain all monitors, osds, and computes want to re-initalize.

```shell
export all="compute-4 controller-1 controller-2 controller-3"
for node in $all
do
 ssh $node 'service ceph -a stop ;
 umount /var/lib/ceph/osd/ceph*';
done;
ceph-deploy purgedata $all;
ceph-deploy purge $all;
yum install -y ceph-deploy;
rm ~/ceph* ;
ceph-deploy install $all
```


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

