class osnailyfacter::astute::service_token_off {

  notice('MODULAR: astute/service_token_off.pp')

  ####################################################################
  # Used as singular by post-deployment action to disable admin_token
  #

  $keystone_params_hash = hiera_hash('keystone', {})

  if $keystone_params_hash['service_token_off'] {

    include ::keystone::params
    include ::tweaks::apache_wrappers

    keystone_config {
      'DEFAULT/admin_token': ensure => absent;
    }

    service { 'httpd':
      ensure => 'running',
      name   => $::tweaks::apache_wrappers::service_name,
      enable => true,
    }

    # Restart service that changes to take effect
    Keystone_config<||> ~> Service['httpd']

    # Get paste.ini source
    $keystone_paste_ini = $::keystone::params::paste_config ? {
      undef   => '/etc/keystone/keystone-paste.ini',
      default => $::keystone::params::paste_config,
    }

    # Disable admin_token_auth middleware in public/admin/v3 pipelines
    include ::keystone::disable_admin_token_auth
    Ini_subsetting <| title == 'public_api/admin_token_auth' |> {
      path => $keystone_paste_ini
    }
    Ini_subsetting <| title == 'admin_api/admin_token_auth' |> {
      path => $keystone_paste_ini
    }
    Ini_subsetting <| title == 'api_v3/admin_token_auth' |> {
      path => $keystone_paste_ini
    }

  }

}
