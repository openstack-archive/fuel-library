# Example proxy using more middlewares:
#  - Keystone: keystone + authtoken
#  - Amazon S3 compatibility: swift3 + s3token
#  - Rate limiting: ratelimit
#  - Catch errors: catch_errors
#
# A keystone service user is required for swift, with admin role on thei
# services tenant.
# The swift service and endpoint must also be created in keystone.
#

$keystone_swift_user = 'swift'
$keystone_swift_pass = 'ChangeMe'
$keystone_services_tenant = 'services'
$keystone_host = '127.0.0.1'
$keystone_auth_port = 35357
$keystone_auth_protocol = 'http'

class { 'swift::proxy':
  proxy_local_net_ip => $swift_local_net_ip,
  pipeline           => [
    'catch_errors',
    'healthcheck',
    'cache',
    'ratelimit',
    'swift3',
    's3token',
    'authtoken',
    'keystone',
    'proxy-server'
  ],
  account_autocreate => true,
  require            => Class['swift::ringbuilder'],
}

class { [
  'swift::proxy::catch_errors',
  'swift::proxy::healthcheck',
  'swift::proxy::cache',
  'swift::proxy::swift3',
]: }

class { 'swift::proxy::ratelimit':
  clock_accuracy         => 1000,
  max_sleep_time_seconds => 60,
  log_sleep_time_seconds => 0,
  rate_buffer_seconds    => 5,
  account_ratelimit      => 0
}

class { 'swift::proxy::s3token':
  auth_host     => $keystone_host,
  auth_port     => $keystone_auth_port,
  auth_protocol => $keystone_auth_protocol,
}

class { 'swift::proxy::keystone':
  operator_roles => ['admin', 'SwiftOperator'],
}

class { 'swift::proxy::authtoken':
  admin_user        => $keystone_swift_user,
  admin_tenant_name => $keystone_services_tenant,
  admin_password    => $keystone_swift_pass,
  auth_host         => $keystone_host,
  auth_port         => $keystone_auth_port,
  auth_protocol     => $keystone_auth_protocol,
}
