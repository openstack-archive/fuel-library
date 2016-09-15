# == Class osnailyfacter::apache_api_proxy
#
# Class for proxy realization using apache
#
# [*master_ip*]
#  (required) String. IP address of master node.
#
# [*max_header_size*]
#  (optional) String. Set the limit on the allowed size
#  of an HTTP request header field.
#
# [*ports*]
#  (optional) List of open ports for connections from master node.
#  (list value)
#
class osnailyfacter::apache_api_proxy(
  $master_ip,
  $max_header_size = '8190',
  $ports           = ['443', '563', '5000', '6385', '8000', '8003', '8004', '8042', '8080',
                        '8082', '8386', '8773', '8774', '8776', '8777', '9292', '9696'],
) {

  # Allow connection to the apache for ostf tests
  firewall {'007 tinyproxy':
    dport   => [ 8888 ],
    source  => $master_ip,
    proto   => 'tcp',
    action  => 'accept',
  }

  include ::apache::mod::proxy
  include ::apache::mod::proxy_connect
  include ::apache::mod::proxy_http
  include ::apache::mod::headers
  include ::apache::mod::reqtimeout

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
