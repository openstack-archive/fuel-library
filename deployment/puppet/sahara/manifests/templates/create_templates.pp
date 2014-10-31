class sahara::templates::create_templates (
  $network_provider = undef,
  $templates_dir    = '/usr/share/sahara/templates',
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

  sahara::templates::template { 'vanilla':
    network_provider => $network_provider,
    templates_dir    => $templates_dir,
  }

  sahara::templates::template { 'hdp':
    network_provider => $network_provider,
    templates_dir    => $templates_dir,
  }

  sahara::templates::template { 'cdh':
    network_provider => $network_provider,
    templates_dir    => $templates_dir,
  }
}
