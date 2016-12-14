class openstack_tasks::keystone::openrc_generate {

  notice('MODULAR: keystone/openrc_generate.pp')

  $access_hash    = hiera_hash('access', {})
  $admin_user     = $access_hash['user']
  $admin_password = $access_hash['password']
  $admin_tenant   = $access_hash['tenant']
  $region         = hiera('region', 'RegionOne')

  $ssl_hash         = hiera_hash('use_ssl', {})
  $management_vip   = hiera('management_vip')
  $service_endpoint = hiera('service_endpoint')
  $internal_port    = '5000'

  $internal_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
  $internal_url      = "${internal_protocol}://${internal_address}:${internal_port}"

  $keystone_hash = hiera_hash('keystone', {})
  $auth_suffix   = pick($keystone_hash['auth_suffix'], '/')
  $auth_url      = "${internal_url}${auth_suffix}"

  $murano_settings = hiera_hash('murano_settings', {})
  $murano_repo_url = pick($murano_settings['murano_repo_url'], 'http://storage.apps.openstack.org')

  $murano_hash         = hiera_hash('murano', {})
  $murano_glare_plugin = dig44($murano_hash, ['plugins', 'glance_artifacts_plugin', 'enabled'], false)

  $operator_user_hash    = hiera_hash('operator_user', {})
  $operator_user_name    = pick($operator_user_hash['name'], 'fueladmin')
  $operator_user_homedir = pick($operator_user_hash['homedir'], '/home/fueladmin')

  $service_user_hash     = hiera_hash('service_user', {})
  $service_user_name     = pick($service_user_hash['name'], 'fuel')
  $service_user_homedir  = pick($service_user_hash['homedir'], '/var/lib/fuel')

  group { 'operator_group' :
    name   => $operator_user_name,
    ensure => present,
  }

  user { 'operator_user':
    name       => $operator_user_name,
    gid        => $operator_user_name,
    ensure     => present,
    managehome => true,
    home       => $operator_user_homedir,
  }

  group { 'service_group' :
    name   => $service_user_name,
    ensure => present,
  }

  user { 'service_user':
    name       => $service_user_name,
    gid        => $service_user_name,
    ensure     => present,
    managehome => true,
    home       => $service_user_homedir,
  }

  $users = {
    "${operator_user_name}" => 'operator_user',
    "${service_user_name}"  => 'service_user',
  }

  $cred_users = {
    '/root/openrc'                    => 'root',
    "${operator_user_homedir}/openrc" => $operator_user_name,
    "${service_user_homedir}/openrc"  => $service_user_name,
  }

  $cred_params = {
    'admin_user'          => $admin_user,
    'admin_password'      => $admin_password,
    'admin_tenant'        => $admin_tenant,
    'region_name'         => $region,
    'auth_url'            => $auth_url,
    'murano_repo_url'     => $murano_repo_url,
    'murano_glare_plugin' => $murano_glare_plugin
  }

  create_resources('osnailyfacter::credentials_file', get_cred_files_hash($cred_users, $cred_params, $users))

}
