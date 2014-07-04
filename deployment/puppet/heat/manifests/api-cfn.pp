# Installs & configure the heat CloudFormation API service
#
class heat::api-cfn (
  $enabled           = true,
  $keystone_host     = '127.0.0.1',
  $keystone_port     = '35357',
  $keystone_protocol = 'http',
  $keystone_user     = 'heat',
  $keystone_tenant   = 'services',
  $keystone_password = false,
  $keystone_ec2_uri  = 'http://127.0.0.1:5000/v2.0/ec2tokens',
  $auth_uri          = 'http://127.0.0.1:5000/v2.0',
  $bind_host         = '0.0.0.0',
  $bind_port         = '8000',
  $verbose           = false,
  $debug             = false,
) {

  warning('heat::api-cfn is deprecated. Use heat::api_cfn instead.')

  class { 'heat::api_cfn':
    enabled           => $enabled,
    keystone_host     => $keystone_host,
    keystone_port     => $keystone_port,
    keystone_protocol => $keystone_protocol,
    keystone_user     => $keystone_user,
    keystone_tenant   => $keystone_tenant,
    keystone_password => $keystone_password,
    keystone_ec2_uri  => $keystone_ec2_uri,
    auth_uri          => $auth_uri,
    bind_host         => $bind_host,
    bind_port         => $bind_port,
    verbose           => $verbose,
    debug             => $debug,
  }
}
