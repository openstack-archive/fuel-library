# == Class: horizon
#
# Installs Horizon dashboard with Apache
#
# === Parameters
#
#  [*secret_key*]
#    (required) Secret key. This is used by Django to provide cryptographic
#    signing, and should be set to a unique, unpredictable value.
#
#  [*fqdn*]
#    (optional) DEPRECATED, use allowed_hosts and server_aliases instead.
#    FQDN(s) used to access Horizon. This is used by Django for
#    security reasons. Can be set to * in environments where security is
#    deemed unimportant. Also used for Server Aliases in web configs.
#    Defaults to ::fqdn
#
#  [*servername*]
#    (optional) FQDN used for the Server Name directives
#    Defaults to ::fqdn.
#
#  [*allowed_hosts*]
#    (optional) List of hosts which will be set as value of ALLOWED_HOSTS
#    parameter in settings_local.py. This is used by Django for
#    security reasons. Can be set to * in environments where security is
#    deemed unimportant.
#    Defaults to ::fqdn.
#
#  [*server_aliases*]
#    (optional) List of names which should be defined as ServerAlias directives
#    in vhost.conf.
#    Defaults to ::fqdn.
#
#  [*package_ensure*]
#    (optional) Package ensure state. Defaults to 'present'.
#
#  [*cache_backend*]
#   (optional) Horizon cache backend.
#   Defaults: 'django.core.cache.backends.locmem.LocMemCache'
#
#  [*cache_options*]
#   (optional) A hash of parameters to enable specific cache options.
#   Defaults to undef
#
#  [*cache_server_ip*]
#    (optional) Memcached IP address. Can be a string, or an array.
#    Defaults to undef.
#
#  [*cache_server_port*]
#    (optional) Memcached port. Defaults to '11211'.
#
#  [*horizon_app_links*]
#    (optional) Array of arrays that can be used to add call-out links
#    to the dashboard for other apps. There is no specific requirement
#    for these apps to be for monitoring, that's just the defacto purpose.
#    Each app is defined in two parts, the display name, and
#    the URIDefaults to false. Defaults to false. (no app links)
#
#  [*keystone_url*]
#    (optional) Full url of keystone public endpoint. (Defaults to 'http://127.0.0.1:5000/v2.0')
#
#  [*keystone_default_role*]
#    (optional) Default Keystone role for new users. Defaults to '_member_'.
#
#  [*django_debug*]
#    (optional) Enable or disable Django debugging. Defaults to 'False'.
#
#  [*openstack_endpoint_type*]
#    (optional) endpoint type to use for the endpoints in the Keystone
#    service catalog. Defaults to 'undef'.
#
#  [*secondary_endpoint_type*]
#    (optional) secondary endpoint type to use for the endpoints in the
#    Keystone service catalog. Defaults to 'undef'.
#
#  [*available_regions*]
#    (optional) List of available regions. Value should be a list of tuple:
#    [ ['urlOne', 'RegionOne'], ['urlTwo', 'RegionTwo'] ]
#    Defaults to undef.
#
#  [*api_result_limit*]
#    (optional) Maximum number of Swift containers/objects to display
#    on a single page. Defaults to 1000.
#
#  [*log_handler*]
#    (optional) Log handler. Defaults to 'file'
#
#  [*log_level*]
#    (optional) Log level. Defaults to 'INFO'. WARNING: Setting this to
#    DEBUG will let plaintext passwords be logged in the Horizon log file.
#
#  [*local_settings_template*]
#    (optional) Location of template to use for local_settings.py generation.
#    Defaults to 'horizon/local_settings.py.erb'.
#
#  [*help_url*]
#    (optional) Location where the documentation should point.
#    Defaults to 'http://docs.openstack.org'.
#
#  [*compress_offline*]
#    (optional) Boolean to enable offline compress of assets.
#    Defaults to True
#
#  [*hypervisor_options*]
#    (optional) A hash of parameters to enable features specific to
#    Hypervisors. These include:
#    'can_set_mount_point': Boolean to enable or disable mount point setting
#      Defaults to 'True'.
#    'can_set_password': Boolean to enable or disable VM password setting.
#      Works only with Xen Hypervisor.
#      Defaults to 'False'.
#
#  [*cinder_options*]
#    (optional) A hash of parameters to enable features specific to
#    Cinder.  These include:
#    'enable_backup': Boolean to enable or disable Cinders's backup feature.
#      Defaults to False.
#
#  [*neutron_options*]
#    (optional) A hash of parameters to enable features specific to
#    Neutron.  These include:
#    'enable_lb': Boolean to enable or disable Neutron's LBaaS feature.
#      Defaults to False.
#    'enable_firewall': Boolean to enable or disable Neutron's FWaaS feature.
#      Defaults to False.
#    'enable_quotas': Boolean to enable or disable Neutron quotas.
#      Defaults to True.
#    'enable_security_group': Boolean to enable or disable Neutron
#      security groups.  Defaults to True.
#    'enable_vpn': Boolean to enable or disable Neutron's VPNaaS feature.
#      Defaults to False.
#    'enable_distributed_router': Boolean to enable or disable Neutron
#      distributed virtual router (DVR) feature in the Router panel.
#      Defaults to False.
#    'enable_ha_router': Enable or disable HA (High Availability) mode in
#      Neutron virtual router in the Router panel.  Defaults to False.
#    'profile_support':  A string indiciating which plugin-specific
#      profiles to enable.  Defaults to 'None', other options include
#      'cisco'.
#
#  [*configure_apache*]
#    (optional) Configure Apache for Horizon. (Defaults to true)
#
#  [*bind_address*]
#    (optional) Bind address in Apache for Horizon. (Defaults to undef)
#
#  [*listen_ssl*]
#    (optional) Enable SSL support in Apache. (Defaults to false)
#
#  [*ssl_redirect*]
#    (optional) Whether to redirect http to https
#    Defaults to True
#
#  [*horizon_cert*]
#    (required with listen_ssl) Certificate to use for SSL support.
#
#  [*horizon_key*]
#    (required with listen_ssl) Private key to use for SSL support.
#
#  [*horizon_ca*]
#    (required with listen_ssl) CA certificate to use for SSL support.
#
#  [*vhost_extra_params*]
#    (optionnal) extra parameter to pass to the apache::vhost class
#    Defaults to undef
#
#  [*file_upload_temp_dir*]
#    (optional) Location to use for temporary storage of images uploaded
#    You must ensure that the path leading to the directory is created
#    already, only the last level directory is created by this manifest.
#    Specify an absolute pathname.
#    Defaults to /tmp
#
# [*policy_files_path*]
#   (Optional) The path to the policy files
#   Defaults to undef.
#
# [*policy_files*]
#   (Optional) Policy files
#   Defaults to undef.
#
# [*can_set_mount_point*]
#   (Optional) DEPRECATED
#   Defaults to 'undef'.
#
#  [*secure_cookies*]
#    (optional) Enables security settings for cookies. Useful when using
#    https on public sites. See: http://docs.openstack.org/developer/horizon/topics/deployment.html#secure-site-recommendations
#    Defaults to false
#
#  [*django_session_engine*]
#    (optional) Selects the session engine for Django to use.
#    Defaults to undefined - will not add entry to local settings.
#
#  [*tuskar_ui*]
#    (optional) Boolean to enable Tuskar-UI related configuration (http://tuskar-ui.readthedocs.org/)
#    Defaults to false
#
#  [*tuskar_ui_ironic_discoverd_url*]
#    (optional) Tuskar-UI - Ironic Discoverd API endpoint
#    Defaults to 'http://127.0.0.1:5050'
#
#  [*tuskar_ui_undercloud_admin_password*]
#    (optional) Tuskar-UI - Undercloud admin password used to authenticate admin user in Tuskar-UI.
#    It is required by Heat to perform certain actions.
#    Defaults to undefined
#
#  [*tuskar_ui_deployment_mode*]
#    (optional) Tuskar-UI - Deployment mode ('poc' or 'scale')
#    Defaults to 'scale'
#
# === Examples
#
#  class { 'horizon':
#    secret_key       => 's3cr3t',
#    keystone_url => 'https://10.0.0.10:5000/v2.0',
#    available_regions => [
#      ['http://region-1.example.com:5000/v2.0', 'Region-1'],
#      ['http://region-2.example.com:5000/v2.0', 'Region-2']
#    ]
#  }
#
class horizon(
  $secret_key,
  $fqdn                                = undef,
  $package_ensure                      = 'present',
  $cache_backend                       = 'django.core.cache.backends.locmem.LocMemCache',
  $cache_options                       = undef,
  $cache_server_ip                     = undef,
  $cache_server_port                   = '11211',
  $horizon_app_links                   = false,
  $keystone_url                        = 'http://127.0.0.1:5000/v2.0',
  $keystone_default_role               = '_member_',
  $django_debug                        = 'False',
  $openstack_endpoint_type             = undef,
  $secondary_endpoint_type             = undef,
  $available_regions                   = undef,
  $api_result_limit                    = 1000,
  $log_handler                         = 'file',
  $log_level                           = 'INFO',
  $help_url                            = 'http://docs.openstack.org',
  $local_settings_template             = 'horizon/local_settings.py.erb',
  $configure_apache                    = true,
  $bind_address                        = undef,
  $servername                          = $::fqdn,
  $server_aliases                      = $::fqdn,
  $allowed_hosts                       = $::fqdn,
  $listen_ssl                          = false,
  $ssl_redirect                        = true,
  $horizon_cert                        = undef,
  $horizon_key                         = undef,
  $horizon_ca                          = undef,
  $compress_offline                    = true,
  $hypervisor_options                  = {},
  $cinder_options                      = {},
  $neutron_options                     = {},
  $file_upload_temp_dir                = '/tmp',
  $policy_files_path                   = undef,
  $policy_files                        = undef,
  $tuskar_ui                           = false,
  $tuskar_ui_ironic_discoverd_url      = 'http://127.0.0.1:5050',
  $tuskar_ui_undercloud_admin_password = undef,
  $tuskar_ui_deployment_mode           = 'scale',
  # DEPRECATED PARAMETERS
  $can_set_mount_point                 = undef,
  $vhost_extra_params                  = undef,
  $secure_cookies                      = false,
  $django_session_engine               = undef,
) {

  include ::horizon::params

  $hypervisor_defaults = {
    'can_set_mount_point' => true,
    'can_set_password'    => false,
  }

  if $fqdn {
    warning('Parameter fqdn is deprecated. Please use parameter allowed_hosts for setting ALLOWED_HOSTS in settings_local.py and parameter server_aliases for setting ServerAlias directives in vhost.conf.')
    $final_allowed_hosts = $fqdn
    $final_server_aliases = $fqdn
  } else {
    $final_allowed_hosts = $allowed_hosts
    $final_server_aliases = $server_aliases
  }

  # Default options for the OPENSTACK_CINDER_FEATURES section. These will
  # be merged with user-provided options when the local_settings.py.erb
  # template is interpolated.
  $cinder_defaults = {
    'enable_backup'         => false,
  }

  # Default options for the OPENSTACK_NEUTRON_NETWORK section.  These will
  # be merged with user-provided options when the local_settings.py.erb
  # template is interpolated.
  $neutron_defaults = {
    'enable_lb'                 => false,
    'enable_firewall'           => false,
    'enable_quotas'             => true,
    'enable_security_group'     => true,
    'enable_vpn'                => false,
    'enable_distributed_router' => false,
    'enable_ha_router'          => false,
    'profile_support'           => 'None',
  }

  Service <| title == 'memcached' |> -> Class['horizon']

  package { 'horizon':
    ensure => $package_ensure,
    name   => $::horizon::params::package_name,
    tag    => 'openstack',
  }

  concat { $::horizon::params::config_file:
    mode    => '0644',
    require => Package['horizon'],
  }

  concat::fragment { 'local_settings.py':
    target  => $::horizon::params::config_file,
    content => template($local_settings_template),
    order   => '50',
  }

  package { 'python-lesscpy':
    ensure  => $package_ensure,
  }

  exec { 'refresh_horizon_django_cache':
    command     => "${::horizon::params::manage_py} collectstatic --noinput --clear && ${::horizon::params::manage_py} compress --force",
    refreshonly => true,
    require     => [Package['python-lesscpy'], Package['horizon']],
  }

  if $compress_offline {
    Concat[$::horizon::params::config_file] ~> Exec['refresh_horizon_django_cache']
  }

  if $configure_apache {
    class { '::horizon::wsgi::apache':
      bind_address   => $bind_address,
      servername     => $servername,
      server_aliases => $final_server_aliases,
      listen_ssl     => $listen_ssl,
      ssl_redirect   => $ssl_redirect,
      horizon_cert   => $horizon_cert,
      horizon_key    => $horizon_key,
      horizon_ca     => $horizon_ca,
      extra_params   => $vhost_extra_params,
    }
  }

  if ! ($file_upload_temp_dir in ['/tmp','/var/tmp']) {
    file { $file_upload_temp_dir :
      ensure => directory,
      owner  => $::horizon::params::wsgi_user,
      group  => $::horizon::params::wsgi_group,
      mode   => '0755',
    }
  }

  $tuskar_ui_deployment_mode_allowed_values = ['scale', 'poc']
  if ! (member($tuskar_ui_deployment_mode_allowed_values, $tuskar_ui_deployment_mode)) {
    fail("'${$tuskar_ui_deployment_mode}' is not correct value for tuskar_ui_deployment_mode parameter. It must be either 'scale' or 'poc'.")
  }
}
