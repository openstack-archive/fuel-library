define cobbler::snippet(){
  file { "/var/lib/cobbler/snippets/${name}":
    content => template("cobbler/snippets/${name}.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package[$::cobbler::packages::cobbler_package],
    notify  => Exec['cobbler_sync']
  }
}
