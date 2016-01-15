# == Class osnailyfacter::apache_api_proxy
#
# Class for proxy realization using apache
#
# [*master_ip*]
# (required) String. IP address of master node.
#
# [*max_header_size*]
# (optional) String. Set the limit on the allowed size
#  of an HTTP request header field.
#
class osnailyfacter::apache_api_proxy(
  $master_ip,
  $max_header_size = '8190',
) {

  # Allow connection to the apache for ostf tests
  firewall {'007 tinyproxy':
    dport   => [ 8888 ],
    source  => $master_ip,
    proto   => 'tcp',
    action  => 'accept',
  }

  class {"::apache::mod::proxy": }
  class {"::apache::mod::proxy_connect": }
  class {"::apache::mod::proxy_http": }
  class {"::apache::mod::headers": }

  $apache_api_proxy_address = hiera('apache_api_proxy_address', '0.0.0.0')

  apache::vhost { 'apache_api_proxy':
    docroot          => '/var/www/html',
    custom_fragment  => template('osnailyfacter/api_proxy.conf.erb'),
    port             => '8888',
    ip               => $apache_api_proxy_address,
    add_listen       => false,
    error_log_syslog => 'syslog:local0',
    log_level        => 'notice',
    ip_based         => true, # Do not setup outdated 'NameVirtualHost' option
  }
}
