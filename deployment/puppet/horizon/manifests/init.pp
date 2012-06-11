#
# installs a horizon server
#
class horizon(
  $cache_server_ip   = '127.0.0.1',
  $cache_server_port = '11211'
) {

  include horizon::params

  if $cache_server_ip =~ /^127\.0\.0\.1/ {
    Class['memcached'] -> Class['horizon']
  }

  package { ['openstack-dashboard',"$::horizon::params::http_service"]:
    ensure => present,
  }

  file { '/etc/openstack-dashboard/local_settings.py':
    content => template('horizon/local_settings.py.erb'),
    mode    => '0644',
  }

  service { 'httpd':
    name      => $::horizon::params::http_service,
    ensure    => 'running',
    require   => Package["$::horizon::params::http_service"],
    subscribe => File['/etc/openstack-dashboard/local_settings.py']
  }
}
