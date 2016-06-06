class osnailyfacter::astute::service_token_off {

  notice('MODULAR: astute/service_token_off.pp')

  ####################################################################
  # Used as singular by post-deployment action to disable admin_token
  #

  $keystone_service_token_off = true

  if $keystone_service_token_off {

    include ::keystone::params

    keystone_config {
      'DEFAULT/admin_token': ensure => absent;
    }

    # Get paste.ini source
    $keystone_paste_ini = $::keystone::params::paste_config ? {
      undef   => '/etc/keystone/keystone-paste.ini',
      default => $::keystone::params::paste_config,
    }

    # Remove admin_token_auth middleware from public/admin/v3 pipelines
    exec { 'remove_admin_token_auth_middleware':
      path    => ['/bin', '/usr/bin'],
      command => "sed -i.dist 's/ admin_token_auth//' ${keystone_paste_ini}",
      onlyif  => "fgrep -q ' admin_token_auth' ${keystone_paste_ini}",
    }

    service { 'keystone':
      ensure => 'running',
      name   => $::keystone::params::service_name,
      enable => true,
    }

    # Restart service so that changes take effect
    Keystone_config<||> ~> Service['keystone']
    Exec['remove_admin_token_auth_middleware'] ~> Service['keystone']

  }

}
