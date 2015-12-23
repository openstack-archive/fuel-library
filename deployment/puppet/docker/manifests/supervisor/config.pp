define docker::supervisor::config( $release) {
  file { "/etc/supervisord.d/${release}/${title}.conf":
    content => template('docker/supervisor/base.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
}
