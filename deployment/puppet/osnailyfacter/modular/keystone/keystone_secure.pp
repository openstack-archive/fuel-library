notice('MODULAR: keystone-secure.pp')

file_line { 'keystone-remove-AdminTokenAuthMiddleware':
  ensure => absent,
  path   => '/etc/keystone/keystone-paste.ini',
  line   => 'paste.filter_factory = keystone.middleware:AdminTokenAuthMiddleware.factory',
} ~>

service { 'keystone': }

