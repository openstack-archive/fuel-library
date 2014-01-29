class ironic::api(
  $rpc_backend = $::ironic::params::rpc_backend,

  $rabbit_host = $::ironic::params::rabbit_host,
  $rabbit_port = $::ironic::params::rabbit_port,
  $rabbit_vhost = $::ironic::params::rabbit_vhost,
  $rabbit_userid = $::ironic::params::rabbit_userid,
  $rabbit_password = $::ironic::params::rabbit_password,

  $qpid_host = $::ironic::params::qpid_host,
  $qpid_username = $::ironic::params::qpid_username,
  $qpid_password = $::ironic::params::qpid_password,

  $cache_dir = $::ironic::params::cache_dir,
  $policy_json = $::ironic::params::policy_json,

  $auth_host = $::ironic::params::auth_host,
  $auth_port = $::ironic::params::auth_port,
  $auth_protocol = $::ironic::params::auth_protocol,
  $auth_uri = $::ironic::params::auth_uri,

  $auth_tenant = $::ironic::params::auth_tenant,
  $auth_user = $::ironic::params::auth_user,
  $auth_password = $::ironic::params::auth_password,
  ) inherits ironic::params {

  ironic_config {
    'DEFAULT/auth_strategy': value => "keystone";
    'DEFAULT/policy_file':   value => $policy_json;
    'DEFAULT/notifier_strategy': value => $rpc_backend;
    'keystone_authtoken/auth_host': value => $auth_host;
    'keystone_authtoken/auth_port': value => $auth_port;
    'keystone_authtoken/auth_protocol': value => $auth_protocol;
    'keystone_authtoken/auth_uri': value => $auth_uri;
    'keystone_authtoken/admin_tenant_name': value => $auth_tenant;
    'keystone_authtoken/admin_user': value => $auth_user;
    'keystone_authtoken/admin_password': value => $auth_password;
    'keystone_authtoken/signing_dir': value => "${cache_dir}/api";
  }

  file { $policy_json :
    source => 'puppet:///modules/ironic/policy.json',
  }

  if $rpc_backend == 'rabbit' {
    ironic_config {
      'DEFAULT/rpc_backend': value => "ironic.openstack.common.rpc.impl_kombu";
      'DEFAULT/rabbit_host': value => $rabbit_host;
      'DEFAULT/rabbit_port': value => $rabbit_port;
      'DEFAULT/rabbit_virtual_host': value => $rabbit_vhost;
      'DEFAULT/rabbit_userid': value => $rabbit_userid;
      'DEFAULT/rabbit_password': value => $rabbit_password;
    }
  }
  elsif $rpc_backend == 'qpid' {
    ironic_config {
      'DEFAULT/rpc_backend': value => "ironic.openstack.common.rpc.impl_qpid";
      'DEFAULT/qpid_hostname': value => $qpid_host;
      'DEFAULT/qpid_username':   value => $qpid_username;
      'DEFAULT/qpid_password': value => $qpid_password;
    }
  }

}
