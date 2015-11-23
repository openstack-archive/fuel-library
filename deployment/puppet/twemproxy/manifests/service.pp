class twemproxy::service inherits twemproxy {

  if $twemproxy::service_manage == true {
    service { $twemproxy::service_name:
      ensure => $twemproxy::service_ensure,
      enable => $twemproxy::service_enable,
    }
  }
}
