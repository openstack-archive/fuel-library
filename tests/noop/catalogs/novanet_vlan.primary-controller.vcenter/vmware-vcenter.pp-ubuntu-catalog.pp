anchor { 'vcenter-nova-network-end':
  name => 'vcenter-nova-network-end',
}

anchor { 'vcenter-nova-network-start':
  before => 'Package[nova-network]',
  name   => 'vcenter-nova-network-start',
}

class { 'Nova::Params':
  name => 'Nova::Params',
}

class { 'Settings':
  name => 'Settings',
}

class { 'Vmware::Controller':
  name             => 'Vmware::Controller',
  use_quantum      => 'false',
  vcenter_host_ip  => '10.10.10.10',
  vcenter_password => 'password',
  vcenter_settings => [{'availability_zone_name' => 'vcenter', 'datastore_regex' => '.*', 'service_name' => 'cluster1', 'target_node' => 'controllers', 'vc_cluster' => 'Cluster1', 'vc_host' => '172.16.0.254', 'vc_password' => 'Qwer!1234', 'vc_user' => 'administrator@vsphere.local'}, {'availability_zone_name' => 'vcenter', 'datastore_regex' => '.*', 'service_name' => 'cluster2', 'target_node' => 'node-4', 'vc_cluster' => 'Cluster2', 'vc_host' => '172.16.0.254', 'vc_password' => 'Qwer!1234', 'vc_user' => 'administrator@vsphere.local'}],
  vcenter_user     => 'user',
  vlan_interface   => 'vmnic0',
  vnc_address      => '172.16.0.3',
}

class { 'Vmware::Network::Nova':
  amqp_port               => '5673',
  ensure_package          => 'present',
  name                    => 'Vmware::Network::Nova',
  nova_network_config     => '/etc/nova/nova.conf',
  nova_network_config_dir => '/etc/nova/nova-network.d',
}

class { 'Vmware::Network':
  name        => 'Vmware::Network',
  use_quantum => 'false',
}

class { 'Vmware':
  ceilometer       => 'false',
  debug            => 'false',
  name             => 'Vmware',
  use_quantum      => 'false',
  vcenter_cluster  => 'cluster',
  vcenter_host_ip  => '10.10.10.10',
  vcenter_password => 'password',
  vcenter_settings => [{'availability_zone_name' => 'vcenter', 'datastore_regex' => '.*', 'service_name' => 'cluster1', 'target_node' => 'controllers', 'vc_cluster' => 'Cluster1', 'vc_host' => '172.16.0.254', 'vc_password' => 'Qwer!1234', 'vc_user' => 'administrator@vsphere.local'}, {'availability_zone_name' => 'vcenter', 'datastore_regex' => '.*', 'service_name' => 'cluster2', 'target_node' => 'node-4', 'vc_cluster' => 'Cluster2', 'vc_host' => '172.16.0.254', 'vc_password' => 'Qwer!1234', 'vc_user' => 'administrator@vsphere.local'}],
  vcenter_user     => 'user',
  vlan_interface   => 'vmnic0',
  vnc_address      => '172.16.0.3',
}

class { 'main':
  name => 'main',
}

cs_resource { 'p_nova_compute_vmware_vcenter-cluster1':
  ensure          => 'present',
  before          => 'Service[p_nova_compute_vmware_vcenter-cluster1]',
  metadata        => {'resource-stickiness' => '1'},
  name            => 'p_nova_compute_vmware_vcenter-cluster1',
  operations      => {'monitor' => {'interval' => '20', 'timeout' => '10'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '30'}},
  parameters      => {'additional_parameters' => '--config-file=/etc/nova/nova-compute.d/vmware-vcenter_cluster1.conf', 'amqp_server_port' => '5673', 'config' => '/etc/nova/nova.conf', 'pid' => '/var/run/nova/nova-compute-vcenter-cluster1.pid'},
  primitive_class => 'ocf',
  primitive_type  => 'nova-compute',
  provided_by     => 'fuel',
}

cs_resource { 'p_vcenter_nova_network':
  ensure          => 'present',
  before          => 'Service[p_vcenter_nova_network]',
  metadata        => {'resource-stickiness' => '1'},
  name            => 'p_vcenter_nova_network',
  operations      => {'monitor' => {'interval' => '20', 'timeout' => '30'}, 'start' => {'timeout' => '20'}, 'stop' => {'timeout' => '20'}},
  parameters      => {'additional_parameters' => '--config-file=/etc/nova/nova-network.d/nova-network-ha.conf', 'amqp_server_port' => '5673', 'auth_url' => 'http://172.16.1.2:5000/v2.0', 'config' => '/etc/nova/nova.conf', 'password' => '77CHLe8y', 'region' => 'RegionOne', 'user' => 'nova'},
  primitive_class => 'ocf',
  primitive_type  => 'nova-network',
  provided_by     => 'fuel',
}

exec { 'networking-refresh':
  command     => '/sbin/ifdown -a ; /sbin/ifup -a',
  refreshonly => 'true',
}

exec { 'post-nova_config':
  command     => '/bin/echo "Nova config has changed"',
  refreshonly => 'true',
}

exec { 'remove_nova-compute_override':
  before  => ['Service[nova-compute]', 'Service[nova-compute]'],
  command => 'rm -f /etc/init/nova-compute.override',
  onlyif  => 'test -f /etc/init/nova-compute.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_nova-network_override':
  before  => ['Service[nova-network]', 'Service[nova-network]'],
  command => 'rm -f /etc/init/nova-network.override',
  onlyif  => 'test -f /etc/init/nova-network.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { '/etc/nova/nova-compute.d/vmware-vcenter_cluster1.conf':
  ensure  => 'present',
  before  => 'Cs_resource[p_nova_compute_vmware_vcenter-cluster1]',
  content => '[DEFAULT]
compute_driver=vmwareapi.VMwareVCDriver
log_file=nova-compute-vmware-vcenter-cluster1.log
host=vcenter-cluster1

[vmware]

cache_prefix=$host

cluster_name=Cluster1
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
  path    => '/etc/nova/nova-compute.d/vmware-vcenter_cluster1.conf',
}

file { '/etc/nova/nova-compute.d':
  ensure => 'directory',
  before => 'File[/etc/nova/nova-compute.d/vmware-vcenter_cluster1.conf]',
  group  => 'nova',
  mode   => '0750',
  owner  => 'nova',
  path   => '/etc/nova/nova-compute.d',
}

file { '/etc/nova/nova-network.d/nova-network-ha.conf':
  ensure  => 'present',
  before  => 'Cs_resource[p_vcenter_nova_network]',
  content => '[DEFAULT]
host=nova-network-ha
',
  group   => 'nova',
  mode    => '0600',
  owner   => 'nova',
  path    => '/etc/nova/nova-network.d/nova-network-ha.conf',
}

file { '/etc/nova/nova-network.d':
  ensure => 'directory',
  before => 'File[/etc/nova/nova-network.d/nova-network-ha.conf]',
  group  => 'nova',
  mode   => '0750',
  owner  => 'nova',
  path   => '/etc/nova/nova-network.d',
}

file { 'create_nova-compute_override':
  ensure  => 'present',
  before  => 'Exec[remove_nova-compute_override]',
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-compute.override',
}

file { 'create_nova-network_override':
  ensure  => 'present',
  before  => ['Package[nova-network]', 'Package[nova-network]', 'Exec[remove_nova-network_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-network.override',
}

nova_config { 'DEFAULT/enabled_apis':
  before => 'Service[nova-compute]',
  name   => 'DEFAULT/enabled_apis',
  value  => 'ec2,osapi_compute,metadata',
}

nova_config { 'DEFAULT/novncproxy_base_url':
  before => 'Service[nova-compute]',
  name   => 'DEFAULT/novncproxy_base_url',
  value  => 'http://172.16.0.3:6080/vnc_auto.html',
}

package { 'cirros-testvmware':
  ensure => 'present',
  name   => 'cirros-testvmware',
}

package { 'nova-common':
  ensure => 'installed',
  name   => 'binutils',
}

package { 'nova-compute':
  ensure => 'present',
  before => 'Service[nova-compute]',
  name   => 'nova-compute',
}

package { 'nova-network':
  ensure => 'present',
  before => ['Service[nova-network]', 'Exec[remove_nova-network_override]', 'Exec[remove_nova-network_override]'],
  name   => 'nova-network',
}

package { 'python-suds':
  ensure => 'present',
  name   => 'python-suds',
}

service { 'nova-compute':
  ensure => 'stopped',
  before => ['Vmware::Compute::Ha[0]', 'Vmware::Compute::Ha[1]'],
  enable => 'false',
  name   => 'nova-compute',
}

service { 'nova-network':
  ensure => 'stopped',
  before => 'File[/etc/nova/nova-network.d]',
  enable => 'false',
  name   => 'nova-network',
}

service { 'p_nova_compute_vmware_vcenter-cluster1':
  ensure   => 'running',
  enable   => 'true',
  name     => 'p_nova_compute_vmware_vcenter-cluster1',
  provider => 'pacemaker',
}

service { 'p_vcenter_nova_network':
  ensure   => 'running',
  before   => 'Anchor[vcenter-nova-network-end]',
  enable   => 'true',
  name     => 'p_vcenter_nova_network',
  provider => 'pacemaker',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'nova-compute':
  name         => 'nova-compute',
  package_name => 'nova-compute-qemu',
  service_name => 'nova-compute',
}

tweaks::ubuntu_service_override { 'nova-network':
  name         => 'nova-network',
  package_name => 'nova-network',
  service_name => 'nova-network',
}

vmware::compute::ha { '0':
  amqp_port              => '5673',
  api_retry_count        => '5',
  availability_zone_name => 'vcenter',
  before                 => 'Class[Vmware::Network]',
  datastore_regex        => '.*',
  maximum_objects        => '100',
  name                   => '0',
  nova_conf              => '/etc/nova/nova.conf',
  nova_conf_dir          => '/etc/nova/nova-compute.d',
  service_name           => 'cluster1',
  target_node            => 'controllers',
  task_poll_interval     => '5.0',
  use_linked_clone       => 'true',
  vc_cluster             => 'Cluster1',
  vc_host                => '172.16.0.254',
  vc_password            => 'Qwer!1234',
  vc_user                => 'administrator@vsphere.local',
}

vmware::compute::ha { '1':
  amqp_port              => '5673',
  api_retry_count        => '5',
  availability_zone_name => 'vcenter',
  before                 => 'Class[Vmware::Network]',
  datastore_regex        => '.*',
  maximum_objects        => '100',
  name                   => '1',
  nova_conf              => '/etc/nova/nova.conf',
  nova_conf_dir          => '/etc/nova/nova-compute.d',
  service_name           => 'cluster2',
  target_node            => 'node-4',
  task_poll_interval     => '5.0',
  use_linked_clone       => 'true',
  vc_cluster             => 'Cluster2',
  vc_host                => '172.16.0.254',
  vc_password            => 'Qwer!1234',
  vc_user                => 'administrator@vsphere.local',
}

