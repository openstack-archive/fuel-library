#
# installs a horizon server
#
#
# - Parameters
# $cache_server_ip      memcached ip address (or VIP)
# $cache_server_port    memcached port
# $swift                (bool) is swift installed
# $quantum              (bool) is quantum installed
# $app_mon            [] array of ['Alert_App_Name','http://alert_app_ip:port']
# $comp_mon          [] array of ['Compute_Mon_App_Name','http://compute_mon_app_ip:port']
# $stor_mon             [] array of ['Stor_Mon_App_Name','http://stor_mon_app_ip:port']
#
class horizon(
  $cache_server_ip   = '127.0.0.1',
  $cache_server_port = '11211',
  $swift = false,
  $quantum = false,
  $app_mon = undef,
  $comp_mon = undef,
  $stor_mon = undef,
) {

  include horizon::params 

  if $alert_mon {
    $monitoring = true
  }
  elsif $compute_mon {
    $monitoring = true
  }
  elsif $stor_mon {
    $monitoring = true
  } else {
    $monitoring = false
  }

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
