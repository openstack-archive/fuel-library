# This class installs and configures Plumgrid Neutron Plugin.
#
# === Parameters
#
# [*director_server*]
#   IP address of the PLUMgrid Director Server
#   Defaults to 127.0.0.1
# [*director_server_port*]
#   Port of the PLUMgrid Director Server.
#   Defaults to 443
# [*username*]
#   PLUMgrid platform username
# [*password*]
#   PLUMgrid platform password
# [*servertimeout*]
#   Request timeout duration (seconds) to PLUMgrid paltform
#   Defaults to 99
# [*connection*]
#   Database connection
#   Defaults to http://127.0.0.1:35357/v2.0
# [*admin_password*]
#   Keystone admin password
# [*controller_priv_host*]
#   Controller private host IP
#   Defaults to 127.0.0.1

class neutron::plugins::plumgrid (
  $director_server       = '127.0.0.1',
  $director_server_port  = '443',
  $username              = undef,
  $password              = undef,
  $servertimeout         = '99',
  $connection            = 'http://127.0.0.1:35357/v2.0',
  $admin_password        = undef,
  $controller_priv_host  = '127.0.0.1',
  $package_ensure        = 'present'
) {

  include ::neutron::params

  Package[neutron-plugin-plumgrid] -> Neutron_plugin_plumgrid<||>
  Neutron_plugin_plumgrid<||> ~> Service['neutron-server']
  Package[neutron-plumlib-plumgrid] -> Neutron_plumlib_plumgrid<||>
  Neutron_plumlib_plumgrid<||> ~> Service['neutron-server']

  ensure_resource('file', '/etc/neutron/plugins/plumgrid', {
    ensure => directory,
    owner  => 'root',
    group  => 'neutron',
    mode   => '0640'}
  )

  # Ensure the neutron package is installed before config is set
  # under both RHEL and Ubuntu
  if ($::neutron::params::server_package) {
    Package['neutron-server'] -> Neutron_plugin_plumgrid<||>
    Package['neutron-server'] -> Neutron_plumlib_plumgrid<||>
  } else {
    Package['neutron'] -> Neutron_plugin_plumgrid<||>
    Package['neutron'] -> Neutron_plumlib_plumgrid<||>
  }

  package { 'neutron-plugin-plumgrid':
    ensure => $package_ensure,
    name   => $::neutron::params::plumgrid_plugin_package
  }

  package { 'neutron-plumlib-plumgrid':
    ensure => $package_ensure,
    name   => $::neutron::params::plumgrid_pythonlib_package
  }

  if $::osfamily == 'Debian' {
    file_line { '/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG':
      path    => '/etc/default/neutron-server',
      match   => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
      line    => "NEUTRON_PLUGIN_CONFIG=${::neutron::params::plumgrid_config_file}",
      require => [ Package['neutron-server'], Package['neutron-plugin-plumgrid'] ],
      notify  => Service['neutron-server'],
    }
  }

  if $::osfamily == 'Redhat' {
    file { '/etc/neutron/plugin.ini':
      ensure  => link,
      target  => $::neutron::params::plumgrid_config_file,
      require => Package['neutron-plugin-plumgrid'],
    }
  }

  neutron_plugin_plumgrid {
    'PLUMgridDirector/director_server':      value => $director_server;
    'PLUMgridDirector/director_server_port': value => $director_server_port;
    'PLUMgridDirector/username':             value => $username;
    'PLUMgridDirector/password':             value => $password, secret =>true;
    'PLUMgridDirector/servertimeout':        value => $servertimeout;
    'database/connection':                   value => $connection;
  }

  neutron_plumlib_plumgrid {
    'keystone_authtoken/admin_user' :       value => 'admin';
    'keystone_authtoken/admin_password':    value => $admin_password, secret =>true;
    'keystone_authtoken/auth_uri':          value => "http://${controller_priv_host}:35357/v2.0";
    'keystone_authtoken/admin_tenant_name': value => 'admin';
    'PLUMgridMetadata/enable_pg_metadata' : value => 'True';
    'PLUMgridMetadata/metadata_mode':       value => 'local';
  }
}
