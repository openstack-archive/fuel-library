#
# TODO - assumes that proxy server is always a memcached server
#
# TODO - the full list of all things that can be configured is here
#  https://github.com/openstack/swift/tree/master/swift/common/middleware
#
# Installs and configures the swift proxy node.
#
# == Parameters
#
#  [*proxy_local_net_ip*]
#    The address that the proxy will bind to.
#
#  [*port*]
#    (optional) The port to which the proxy server will bind.
#    Defaults to 8080.
#
#  [*pipeline*]
#    (optional) The list of elements of the swift proxy pipeline.
#    Currently supports healthcheck, cache, proxy-server, and
#    one of the following auth_types: tempauth, swauth, keystone.
#    Each of the specified elements also need to be declared externally
#    as a puppet class with the exception of proxy-server.
#    Defaults to ['healthcheck', 'cache', 'tempauth', 'proxy-server']
#
#  [*workers*]
#    (optional) Number of threads to process requests.
#    Defaults to the number of processors.
#
#  [*allow_account_management*]
#    (optional) Rather or not requests through this proxy can create and
#    delete accounts.
#    Defaults to true.
#
#  [*account_autocreate*]
#    (optional) Rather accounts should automatically be created.
#    Has to be set to true for tempauth.
#    Defaults to true.
#
#  [*log_headers*]
#    (optional) If True, log headers in each request
#    Defaults to False.
#
#  [*log_udp_host*]
#    (optional) If not set, the UDP receiver for syslog is disabled.
#    Defaults to an empty string
#
#  [*log_udp_port*]
#    (optional) Port value for UDP receiver, if enabled.
#    Defaults to an empty string
#
#  [*log_address*]
#    (optional) Location where syslog sends the logs to.
#    Defaults to '/dev/log'.
#
#  [*log_level*]
#    (optional) Log level.
#    Defaults to 'INFO'.
#
#  [*log_facility*]
#    (optional) Log level
#    Defaults to 'LOG_LOCAL1'.
#
#  [*log_handoffs*]
#     (optional) If True, the proxy will log whenever it has to failover to a handoff node
#     Defaults to true.
#
#  [*read_affinity*]
#    (optional) Configures the read affinity of proxy-server.
#    Defaults to undef.
#
#  [*write_affinity*]
#    (optional) Configures the write affinity of proxy-server.
#    Defaults to undef.
#
#  [*write_affinity_node_count*]
#    (optional) Configures write_affinity_node_count for proxy-server.
#    Optional but requires write_affinity to be set.
#    Defaults to undef.
#
#  [*node_timeout*]
#    (optional) Configures node_timeout for swift proxy-server
#    Defaults to undef.
#
#  [*enabled*]
#    (optional) Should the service be enabled.
#    Defaults to true
#
#  [*manage_service*]
#    (optional) Whether the service should be managed by Puppet.
#    Defaults to true.
#
#  [*package_ensure*]
#    (optional) Ensure state of the swift proxy package.
#    Defaults to present.
#
#  [*log_name*]
#    Configures log_name for swift proxy-server.
#    Optional. Defaults to proxy-server
#
# == Examples
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2011 Puppetlabs Inc, unless otherwise noted.
#
class swift::proxy(
  $proxy_local_net_ip,
  $port                      = '8080',
  $pipeline                  = ['healthcheck', 'cache', 'tempauth', 'proxy-server'],
  $workers                   = $::processorcount,
  $allow_account_management  = true,
  $account_autocreate        = true,
  $log_headers               = 'False',
  $log_udp_host              = undef,
  $log_udp_port              = undef,
  $log_address               = '/dev/log',
  $log_level                 = 'INFO',
  $log_facility              = 'LOG_LOCAL1',
  $log_handoffs              = true,
  $log_name                  = 'proxy-server',
  $read_affinity             = undef,
  $write_affinity            = undef,
  $write_affinity_node_count = undef,
  $node_timeout              = undef,
  $manage_service            = true,
  $enabled                   = true,
  $package_ensure            = 'present'
) {

  include ::swift::params
  include ::concat::setup

  Swift_config<| |> ~> Service['swift-proxy']

  validate_bool($account_autocreate)
  validate_bool($allow_account_management)
  validate_array($pipeline)

  if($write_affinity_node_count and ! $write_affinity) {
    fail('Usage of write_affinity_node_count requires write_affinity to be set')
  }

  if(member($pipeline, 'tempauth')) {
    $auth_type = 'tempauth'
  } elsif(member($pipeline, 'swauth')) {
    $auth_type = 'swauth'
  } elsif(member($pipeline, 'keystone')) {
    $auth_type = 'keystone'
  } else {
    warning('no auth type provided in the pipeline')
  }

  if(! member($pipeline, 'proxy-server')) {
    warning('pipeline parameter must contain proxy-server')
  }

  if($auth_type == 'tempauth' and ! $account_autocreate ){
    fail('account_autocreate must be set to true when auth_type is tempauth')
  }

  if ($log_udp_port and !$log_udp_host) {
    fail ('log_udp_port requires log_udp_host to be set')
  }

  package { 'swift-proxy':
    ensure => $package_ensure,
    name   => $::swift::params::proxy_package_name,
    tag    => 'openstack',
  }

  concat { '/etc/swift/proxy-server.conf':
    owner   => 'swift',
    group   => 'swift',
    mode    => '0660',
    require => Package['swift-proxy'],
  }

  $required_classes = split(
    inline_template(
      "<%=
          (@pipeline - ['proxy-server']).collect do |x|
            'swift::proxy::' + x.gsub(/-/){ %q(_) }
          end.join(',')
      %>"), ',')

  # you can now add your custom fragments at the user level
  concat::fragment { 'swift_proxy':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy-server.conf.erb'),
    order   => '00',
    # require classes for each of the elements of the pipeline
    # this is to ensure the user gets reasonable elements if he
    # does not specify the backends for every specified element of
    # the pipeline
    before  => Class[$required_classes],
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  service { 'swift-proxy':
    ensure    => $service_ensure,
    name      => $::swift::params::proxy_service_name,
    enable    => $enabled,
    provider  => $::swift::params::service_provider,
    hasstatus => true,
    subscribe => Concat['/etc/swift/proxy-server.conf'],
  }
}
