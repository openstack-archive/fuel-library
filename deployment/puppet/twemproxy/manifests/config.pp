class twemproxy::config inherits twemproxy {

  if $twemproxy::package_manage {
    file { '/etc/default/twemproxy':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('twemproxy/config.erb'),
    }
  }
}
