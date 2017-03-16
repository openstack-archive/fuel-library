class fuel::dsscheduler(
  $scheduler_host = 'localhost',
  $scheduler_port = '8002',
  $user           = 'serializer',
  $enabled        = true,
){
  if !is_bool($enabled) {
    fail('"enabled" variable value must be boolean')
  }

  if !defined(Group["$user"]) {
    group { "$user":
      ensure => present,
      name   => $title,
    }
  }

  if !defined(User["$user"]) {
    user { "$user":
      ensure  => present,
      name    => $title,
      gid     => $user,
      require => Group[$user]
    }
  }

  $systemd_base = '/etc/systemd/system'
  $service_name = "dsscheduler"

  file { "${systemd_base}/${service_name}.service":
    ensure  => present,
    content => template("fuel/${service_name}.service.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => User[$user],
  } ->

  service { $service_name:
    ensure => $enabled,
    enable => $enabled,
  }
}
