class sahara::templates::create_templates (
  $network_provider = undef,
  $templates_dir    = $sahara::params::templates_dir,
  $auth_uri         = 'http://127.0.0.1:5000/v2.0/',
  $auth_user        = 'sahara',
  $auth_tenant      = 'services',
  $auth_password    = 'sahara',
) inherits sahara::params {

  exec {"check_templates":
    command => '/bin/true',
    onlyif => "/usr/bin/test -e ${templates_dir},{templates_dir}/create_templates.sh",
  }

  Sahara::Templates::Template {
    network_provider => $network_provider,
    templates_dir    => $templates_dir,
    user             => $auth_user,
    password         => $auth_password,
    tenant           => $auth_tenant,
    auth_uri         => $auth_uri,
  }

  sahara::templates::template { ['vanilla', 'hdp', 'cdh']: }
}
