class swift::auth_file (
  $admin_tenant,
  $admin_password,
  $admin_user      = 'admin',
  $auth_url        = 'http://127.0.0.1:5000/v2.0/'
) {

  file { '/root/swiftrc':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content =>
  "
  export ST_USER=${admin_tenant}:${admin_user}
  export ST_KEY=${admin_password}
  export ST_AUTH=${auth_url}
  "
  }
}
