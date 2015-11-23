class twemproxy::install inherits twemproxy {

  if $twemproxy::package_manage {
    package { $twemproxy::package_name:
      ensure => $twemproxy::package_ensure,
    }
  }
}
