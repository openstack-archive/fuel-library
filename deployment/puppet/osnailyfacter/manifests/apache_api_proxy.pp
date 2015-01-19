# Proxy realization via apache
class osnailyfacter::apache_api_proxy(
  $master_ip,
) {

  # Allow connection to the apache for ostf tests
  firewall {'007 tinyproxy':
    dport   => [ 8888 ],
    source  => $::fuel_settings['master_ip'],
    proto   => 'tcp',
    action  => 'accept',
    require => Class['openstack::firewall'],
  }

  class {"::apache::mod::proxy": }
  class {"::apache::mod::proxy_connect": }
  class {"::apache::mod::proxy_http": }

  apache::vhost { 'apache_api_proxy':
    docroot          => '/var/www/html',
    custom_fragment  => template('osnailyfacter/api_proxy.conf.erb'),
    port             => '8888',
    add_listen       => true,
    error_log_syslog => 'syslog:local1',
    log_level        => 'debug',
  }
}
