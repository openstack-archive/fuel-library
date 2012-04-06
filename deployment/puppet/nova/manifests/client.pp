class nova::client(

) {

  package { 'python-novaclient':
    ensure => present,
  }

}
