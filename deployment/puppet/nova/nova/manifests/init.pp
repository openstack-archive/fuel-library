class nova( $novaConfHash ) {

  class { 'puppet': }
  class {
    [
      'bzr',
      'git',
      'gcc',
      'extrapackages',
      # I may need to move python-mysqldb to elsewhere if it depends on mysql
      'python',
    ]:
  } 
  package { "python-greenlet": ensure => present }

  package { ["nova-common", "nova-doc"]:
    ensure => present,
    require => Package["python-greenlet"]
  }

  file { "/etc/nova/nova.conf":
    ensure => present,
    content => template("nova/nova.conf.erb"),
    require => Package["nova-common"]
  }
}
