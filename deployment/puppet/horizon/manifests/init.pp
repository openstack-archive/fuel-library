#
# installs a horizon server
#
class horizon(
  $cache_server_ip   = '127.0.0.1',
  $cache_server_port = '11211'
) {

  if $cache_server_ip =~ /^127\.0\.0\.1/ {
    Class['memcached'] -> Class['horizon']
  }

  package { 'openstack-dashboard':
    ensure => present,
  }

  file { '/etc/openstack-dashboard/local_settings.py':
    content => template('horizon/local_settings.py.erb'),
    mode    => '0644',
  }

  service { 'httpd':
    name      => $::horizon::params::http_service,
    ensure    => 'running',
    subscribe => File['/etc/openstack-dashboard/local_settings.py']
  }
}
