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
  $verbose                = 'True',
  $use_syslog             = false
) {

  include cinder::params

  if !defined(Package[$::cinder::params::qemuimg_package_name])
  {
    package {"$::cinder::params::qemuimg_package_name":}
  }

  package { 'python-cinder':
        ensure  => $package_ensure,
         }
  Package['cinder'] -> Cinder_config<||>
  Package['cinder'] -> Cinder_api_paste_ini<||>

  package { 'cinder':
    name => $::cinder::params::package_name,
    ensure => $package_ensure,
  }

if $use_syslog {
  cinder_config {'DEFAULT/log_config': value => "/etc/cinder/logging.conf";}
  file { "cinder-logging.conf":
    content => template('cinder/logging.conf.erb'),
    path => "/etc/cinder/logging.conf",
    owner => "cinder",
    group => "cinder",
  }
  file { "cinder-all.log":
    path => "/var/log/cinder-all.log",
    owner => "cinder",
    group => "cinder",
  }
## Todo rsyslog config
  file { '/etc/rsyslog.d/cinder.conf':
    ensure => present,
    content => "local3.* -/var/log/cinder-all.log"
  }
}
else {
	cinder_config {'DEFAULT/log_config': ensure=>absent;}
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
    cinder_config {
    'DEFAULT/rabbit_host':         value => $rabbit_host;
    }
  }
  if $rabbit_hosts
  {
    cinder_config {
    'DEFAULT/rabbit_hosts':         value => $rabbit_hosts;
    }
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
  exec { 'cinder-manage db_sync':
    command     => $::cinder::params::db_sync_command,
    path        => '/usr/bin',
    user        => 'cinder',
    refreshonly => true,
    logoutput   => 'on_failure',
    tries       => 10,
    try_sleep   => 3,
  }
  Cinder_config<||> -> Exec['cinder-manage db_sync']
  Nova_config<||> -> Exec['cinder-manage db_sync']
  Cinder_api_paste_ini<||> -> Exec['cinder-manage db_sync']
 Exec['cinder-manage db_sync'] -> Service<| title == 'cinder-api' |>
 Exec['cinder-manage db_sync'] -> Service<| title == 'cinder-volume' |>
 Exec['cinder-manage db_sync'] -> Service<| title == 'cinder-scheduler' |>
}
