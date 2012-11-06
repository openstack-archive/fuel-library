#
# parameters that may need to be added
# $state_path = /opt/stack/data/cinder
# $osapi_volume_extension = cinder.api.openstack.volume.contrib.standard_extensions
# $root_helper = sudo /usr/local/bin/cinder-rootwrap /etc/cinder/rootwrap.conf
class cinder::base (
  $rabbit_password,
  $sql_connection,
  $rpc_backend            = 'cinder.openstack.common.rpc.impl_kombu',
  $rabbit_host            = false,
  $rabbit_hosts           = ['127.0.0.1'],
  $rabbit_port            = 5672,
  $rabbit_virtual_host    = '/',
  $rabbit_userid          = 'nova',
  $package_ensure         = 'present',
  $verbose                = 'True'
) {

  include cinder::params

  Package['cinder'] -> Cinder_config<||>
  Package['cinder'] -> Cinder_api_paste_ini<||>

  package { 'cinder':
    name => $::cinder::params::package_name,
    ensure => $package_ensure,
  }

  File {
    ensure  => present,
    owner   => 'cinder',
    group   => 'cinder',
    mode    => '0644',
    require => Package[$::cinder::params::package_name],
  }

  file { $::cinder::params::cinder_conf: }
  file { $::cinder::params::cinder_paste_api_ini: }

  # Temporary fixes
  file { ['/var/log/cinder', '/var/lib/cinder']:
    ensure => directory,
    owner  => 'cinder',
    group  => 'cinder',
  }
  if $rabbit_host
  {
    'DEFAULT/rabbit_host':         value => $rabbit_host;
  }
  if $rabbit_hosts
  {
    'DEFAULT/rabbit_hosts':         value => $rabbit_hosts;
    'DEFAULT/rabbit_ha_queues': value => 'True';
  }
  cinder_config {
    'DEFAULT/rpc_backend':         value => $rpc_backend;
    'DEFAULT/rabbit_password':     value => $rabbit_password;
    'DEFAULT/rabbit_port':         value => $rabbit_port;
    'DEFAULT/rabbit_virtual_host': value => $rabbit_virtual_host;
    'DEFAULT/rabbit_userid':       value => $rabbit_userid;
    'DEFAULT/sql_connection':      value => $sql_connection;
    'DEFAULT/verbose':             value => $verbose;
    'DEFAULT/api_paste_config':    value => '/etc/cinder/api-paste.ini';
  }

}
