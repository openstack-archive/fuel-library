class twemproxy::service inherits twemproxy {

  if $twemproxy::params::service_manage == true {
    service { 'twemproxy':
      ensure => $twemproxy::params::service_ensure,
      enable => $twemproxy::params::service_enable,
      name   => $twemproxy::params::service_name,
    }
  }
}
