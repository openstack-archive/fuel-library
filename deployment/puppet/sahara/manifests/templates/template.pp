# creating Sahara cluster and node group templates

define sahara::templates::template (
  $network_provider = undef,
  $templates_dir    = '/usr/share/sahara/templates',
  $plugin           = $title,
) {
  include sahara
  include sahara::api

  exec { "${plugin}_create_templates":
    path    => "/bin:/usr/bin",
    cwd     => "${templates_dir}",
    command => "bash -c \"source /root/openrc; sahara node-group-template-list | grep -q ${plugin}\"",
    unless  => "bash create_templates.sh ${network_provider} ${plugin}",
    require => [ File['/root/openrc'], File['script_templates'] ],
  }
}
