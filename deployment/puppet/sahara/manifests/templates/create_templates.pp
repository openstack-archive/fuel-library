class sahara::templates::create_templates (
  $network_provider = undef,
  $templates_dir    = '/usr/share/sahara/templates',
  $auth_uri         = 'http://127.0.0.1:5000/v2.0/',
  $auth_user        = 'sahara',
  $auth_tenant      = 'services',
  $auth_password    = 'sahara',
) {

  file { 'create_templates':
    path         => "${templates_dir}",
    ensure       => directory,
    owner        => 'root',
    group        => 'root',
    mode         => '0755',
    source       => 'puppet:///modules/sahara/templates',
    recurse      => true,
    require      => Package['sahara'],
  }

  file { 'script_templates':
    path     => "${templates_dir}/create_templates.sh",
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    mode     => '0755',
    source   => 'puppet:///modules/sahara/create_templates.sh',
    require  => [ Package['sahara'], File['create_templates'] ],
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
