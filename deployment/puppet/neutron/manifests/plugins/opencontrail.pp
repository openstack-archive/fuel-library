# This class installs and configures Opencontrail Neutron Plugin.
#
# === Parameters
#
# [*api_server_ip*]
#   IP address of the API Server
#   Defaults to undef
#
# [*api_server_port*]
#   Port of the API Server.
#   Defaults to undef
#
# [*multi_tenancy*]
#   Whether to enable multi-tenancy
#   Default to undef
#
# [*contrail_extensions*]
#   Array of OpenContrail extensions to be supported
#   Defaults to undef
#   Example:
#
#     class {'neutron::plugins::opencontrail' :
#       contrail_extensions => ['ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam']
#     }
#
# [*keystone_auth_url*]
#   Url of the keystone auth server
#   Defaults to undef
#
# [*keystone_admin_user*]
#   Admin user name
#   Defaults to undef
#
# [*keystone_admin_tenant_name*]
#   Admin_tenant_name
#   Defaults to undef
#
# [*keystone_admin_password*]
#   Admin password
#   Defaults to undef
#
# [*keystone_admin_token*]
#   Admin token
#   Defaults to undef
#
class neutron::plugins::opencontrail (
  $api_server_ip              = undef,
  $api_server_port            = undef,
  $multi_tenancy              = undef,
  $contrail_extensions        = undef,
  $keystone_auth_url          = undef,
  $keystone_admin_user        = undef,
  $keystone_admin_tenant_name = undef,
  $keystone_admin_password    = undef,
  $keystone_admin_token       = undef,
  $package_ensure             = 'present',
) {

  include ::neutron::params

  validate_array($contrail_extensions)

  package { 'neutron-plugin-contrail':
    ensure => $package_ensure,
    name   => $::neutron::params::opencontrail_plugin_package,
    tag    => 'openstack',
  }

  # Although this manifest does not install opencontrail plugin package because it
  # is not available in common distro repos, this statement forces you to
  # have an orchestrator/wrapper manifest that does that job.
  Package[$::neutron::params::opencontrail_plugin_package] -> Neutron_plugin_opencontrail<||>
  Neutron_plugin_opencontrail<||> ~> Service['neutron-server']

  ensure_resource('file', '/etc/neutron/plugins/opencontrail', {
    ensure => directory,
    owner  => 'root',
    group  => 'neutron',
    mode   => '0640'}
  )

  # Ensure the neutron package is installed before config is set
  # under both RHEL and Ubuntu
  if ($::neutron::params::server_package) {
    Package['neutron-server'] -> Neutron_plugin_opencontrail<||>
  } else {
    Package['neutron'] -> Neutron_plugin_opencontrail<||>
  }

  if $::osfamily == 'Debian' {
    file_line { '/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG':
      path    => '/etc/default/neutron-server',
      match   => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
      line    => "NEUTRON_PLUGIN_CONFIG=${::neutron::params::opencontrail_config_file}",
      require => [ Package['neutron-server'], Package[$::neutron::params::opencontrail_plugin_package] ],
      notify  => Service['neutron-server'],
    }
  }

  if $::osfamily == 'Redhat' {
    file { '/etc/neutron/plugin.ini':
      ensure  => link,
      target  => $::neutron::params::opencontrail_config_file,
      require => Package[$::neutron::params::opencontrail_plugin_package],
    }
  }

  neutron_plugin_opencontrail {
    'APISERVER/api_server_ip':       value => $api_server_ip;
    'APISERVER/api_server_port':     value => $api_server_port;
    'APISERVER/multi_tenancy':       value => $multi_tenancy;
    'APISERVER/contrail_extensions': value => join($contrail_extensions, ',');
    'KEYSTONE/auth_url':             value => $keystone_auth_url;
    'KEYSTONE/admin_user' :          value => $keystone_admin_user;
    'KEYSTONE/admin_tenant_name':    value => $keystone_admin_tenant_name;
    'KEYSTONE/admin_password':       value => $keystone_admin_password, secret =>true;
    'KEYSTONE/admin_token':          value => $keystone_admin_token, secret =>true;
  }

}
