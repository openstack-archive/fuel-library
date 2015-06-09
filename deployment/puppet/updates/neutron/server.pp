class updates::neutron::server inherits neutron::params {

  package { $package_name :
    ensure => 'latest',
  }

  if $server_package {
    package {  $server_package :
      ensure => 'latest',
    }
  }

  package { $client_package :
    ensure => 'latest',
  }

  service { $server_service :
    ensure => 'running',
    enable => true,
  }

  neutron_config { 'DEFAULT/api-workers' :
    value  => $::processorcount / 2,
  }

  Package<||> ~> Service<||>
  Neutron_config<||> ~> Service<||>

}
