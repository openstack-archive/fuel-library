class murano::python_muranoclient {

  include murano::params

  package { 'murano_python_muranoclient':
    ensure => installed,
    name   => $::murano::params::python_muranoclient_package_name,
  }

}
