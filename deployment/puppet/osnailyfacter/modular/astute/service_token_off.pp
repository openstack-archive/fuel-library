notice('MODULAR: service_token_off.pp')

####################################################################
# Used as singular by post-deployment action to disable admin_token
#

include horizon::params
include keystone::params

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
  command => "sed -i.dist 's/ admin_token_auth//' $keystone_paste_ini",
  onlyif  => "fgrep -q ' admin_token_auth' $keystone_paste_ini",
}

service { 'httpd':
  ensure     => 'running',
  name       => $::horizon::params::http_service,
  enable     => true,
  hasrestart => true,
  restart    => 'apachectl graceful',
}

# Restart service that changes to take effect
Keystone_config<||> ~> Service['httpd']
Exec['remove_admin_token_auth_middleware'] ~> Service['httpd']
