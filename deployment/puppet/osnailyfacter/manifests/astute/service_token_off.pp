class osnailyfacter::astute::service_token_off {

  notice('MODULAR: astute/service_token_off.pp')

  ####################################################################
  # Used as singular by post-deployment action to disable admin_token
  #

  $keystone_params_hash = hiera_hash('keystone', {})

  if $keystone_params_hash['service_token_off'] {

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

    # Disable admin_token_auth middleware in public/admin/v3 pipelines
    include ::keystone::disable_admin_token_auth

  }

}
