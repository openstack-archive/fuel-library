class ironic::params {
  $rpc_backend = 'rabbit' #or qpid

  $rabbit_host = '127.0.0.1'
  $rabbit_port = '5672'
  $rabbit_vhost = '/'
  $rabbit_userid = 'ironic'
  $rabbit_password = 'ironic'

  $qpid_host = '127.0.0.1'
  $qpid_username = 'ironic'
  $qpid_password = 'ironic'

  $email = 'ironic@example.com'

  $ironic_api_protocol = 'http'
  $ironic_api_public_address = '127.0.0.1'
  $ironic_api_admin_address = '127.0.0.1'
  $ironic_api_internal_address = '127.0.0.1'
  $ironic_api_port = '6385'

  $cache_dir = '/var/cache/ironic'
  $policy_json = '/etc/ironic/policy.json'

  $auth_host = '127.0.0.1'
  $auth_port = '35357'
  $auth_protocol = 'http'
  $auth_uri = "${auth_protocol}://${auth_host}:${auth_port}/"
  $auth_tenant = 'services'
  $auth_user = 'ironic'
  $auth_password = 'password'

  $db_host = '127.0.0.1'
  $db_port = '5432'
  $db_protocol = 'postgresql'
  $db_user = 'ironic'
  $db_password = 'ironic'
  $db_name = 'ironic'

  $venv = '/opt/ironic'
  $source = '/root'
}
