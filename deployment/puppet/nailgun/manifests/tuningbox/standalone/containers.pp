class nailgun::tuningbox::standalone::containers (
  $keystone_host    = $::nailgun::tuningbox::params::keystone_host,
  $keystone_user    = $::nailgun::tuningbox::params::keystone_user,
  $keystone_pass    = $::nailgun::tuningbox::params::keystone_pass,

  $db_host          = $::nailgun::tuningbox::params::keystone_host,
  $db_user          = $::nailgun::tuningbox::params::keystone_user,
  $db_name          = $::nailgun::tuningbox::params::keystone_user,
  $db_pass          = $::nailgun::tuningbox::params::keystone_pass,
  ) inherits nailgun::tuningbox::params {

  define sync_container($module_source_path, $module_dest_path, $check_command, $container_name = $title){
    exec {"sync_${container_name}_module":
      path    => '/usr/bin:/bin:/usr/sbin:/sbin',
      command => "dockerctl copy ${module_source_path} ${container_name}:${module_dest_path}",
    }

    service {"docker-${container_name}":
      ensure  => 'running',
    }

    exec { "check_${container_name}":
      command   => "${check_command}",
      path      => '/usr/bin:/bin:/usr/sbin:/sbin',
      tries     => 6,
      try_sleep => 20,
    }

    Exec["sync_${container_name}_module"] ~>
    Service["docker-${container_name}"] ->
    Exec["check_${container_name}"]
  }

  $keystone_url = "http://${keystone_host}:35357/v2.0"

  sync_container {'keystone':
    module_source_path => '/etc/puppet/modules/nailgun/',
    module_dest_path   => '/etc/puppet/modules/',
    check_command      => "dockerctl shell keystone /bin/sh -c \"keystone  --os-auth-url \"${keystone_url}\" --os-username \"${keystone_user}\" --os-password \"${keystone_pass}\" token-get &>/dev/null\""
  }

  sync_container {'postgres':
    module_source_path => '/etc/puppet/modules/nailgun/',
    module_dest_path   => '/etc/puppet/modules/',
    check_command      => "dockerctl shell postgres /bin/sh -c \"export PGPASSWORD=${db_pass}; /usr/bin/psql -h ${db_host} -U \"${db_user}\" \"${db_name}\" -c '\copyright' 2>&1 1>/dev/null\"",
  }

  Sync_container ['keystone'] ->
  Sync_container ['postgres']
} 
