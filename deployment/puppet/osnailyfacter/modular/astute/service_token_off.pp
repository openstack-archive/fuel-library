notice('MODULAR: service_token_off.pp')

####################################################################
# Used as singular by post-deployment action to disable admin_token
#

include horizon::params

keystone_config {
  'DEFAULT/admin_token': ensure => absent;
}

service { 'httpd':
  ensure     => 'running',
  name       => $::horizon::params::http_service,
  enable     => true,
  hasrestart => true,
  restart    => 'apachectl graceful',
}

Keystone_config <| |> ~> Service['httpd']

