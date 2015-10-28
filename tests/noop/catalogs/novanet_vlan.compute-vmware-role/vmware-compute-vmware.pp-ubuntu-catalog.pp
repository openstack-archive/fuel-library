class { 'Nova::Params':
  name => 'Nova::Params',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

file { '/etc/nova/nova-compute.conf':
  ensure  => 'present',
  before  => 'Service[nova-compute]',
  content => '[DEFAULT]
compute_driver=vmwareapi.VMwareVCDriver
log_file=nova-compute-vmware-vcenter-cluster2.log
host=vcenter-cluster2

[vmware]

cache_prefix=$host

cluster_name=Cluster2
host_ip=172.16.0.254
host_username=administrator@vsphere.local
host_password=Qwer!1234

api_retry_count=5
maximum_objects=100
task_poll_interval=5.0
datastore_regex=.*
vlan_interface=vmnic0
use_linked_clone=true
',
  group   => 'nova',
  mode    => '0600',
  owner   => 'nova',
  path    => '/etc/nova/nova-compute.conf',
}

package { 'nova-compute':
  ensure => 'installed',
  before => 'File[/etc/nova/nova-compute.conf]',
  name   => 'nova-compute',
}

package { 'python-oslo.vmware':
  ensure => 'installed',
  before => 'Package[nova-compute]',
  name   => 'python-oslo.vmware',
}

service { 'nova-compute':
  ensure => 'running',
  enable => 'true',
  name   => 'nova-compute',
}

stage { 'main':
  name => 'main',
}

vmware::compute_vmware { '0':
  api_retry_count        => '5',
  availability_zone_name => 'vcenter',
  current_node           => 'node-4',
  datastore_regex        => '.*',
  maximum_objects        => '100',
  name                   => '0',
  nova_compute_conf      => '/etc/nova/nova-compute.conf',
  service_name           => 'cluster1',
  target_node            => 'controllers',
  task_poll_interval     => '5.0',
  use_linked_clone       => 'true',
  vc_cluster             => 'Cluster1',
  vc_host                => '172.16.0.254',
  vc_password            => 'Qwer!1234',
  vc_user                => 'administrator@vsphere.local',
  vlan_interface         => 'vmnic0',
}

vmware::compute_vmware { '1':
  api_retry_count        => '5',
  availability_zone_name => 'vcenter',
  current_node           => 'node-4',
  datastore_regex        => '.*',
  maximum_objects        => '100',
  name                   => '1',
  nova_compute_conf      => '/etc/nova/nova-compute.conf',
  service_name           => 'cluster2',
  target_node            => 'node-4',
  task_poll_interval     => '5.0',
  use_linked_clone       => 'true',
  vc_cluster             => 'Cluster2',
  vc_host                => '172.16.0.254',
  vc_password            => 'Qwer!1234',
  vc_user                => 'administrator@vsphere.local',
  vlan_interface         => 'vmnic0',
}

