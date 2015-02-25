# creating Sahara cluster and node group templates

define sahara::templates::template (
  $network_provider = undef,
  $templates_dir    = '/usr/share/sahara/templates',
  $plugin           = $title,
  $auth_uri         = 'http://127.0.0.1:5000/v2.0/',
  $auth_user        = 'sahara',
  $auth_tenant      = 'services',
  $auth_password    = 'sahara',

) {
  include sahara
  include sahara::api

  exec { "${plugin}_create_templates":
    environment => [
      "OS_TENANT_NAME=${auth_tenant}",
      "OS_USERNAME=${auth_user}",
      "OS_PASSWORD=${auth_password}",
      "OS_AUTH_URL=${auth_uri}",
    ],
    path    => "/bin:/usr/bin",
    cwd     => "${templates_dir}",
    unless  => "bash -c \"sahara node-group-template-list | grep -q ${plugin}\"",
    command => "bash create_templates.sh ${network_provider} ${plugin}",
    timeout => 450,
    require => File['script_templates'],
  }
}
