class quantum (
  $enabled              = true,
  $package_ensure       = true,
  $log_verbose          = "False",
  $log_debug            = "False",

  $bind_host            = "0.0.0.0",
  $bind_port            = "9696",
  $sql_connection       = "sqlite:///var/lib/quantum/quantum.sqlite",

  $auth_type            = "keystone",
  $auth_host            = "localhost",
  $auth_port            = "35357",
  $auth_uri             = "http://localhost:5000",
  $keystone_tenant      = "service",
  $keystone_user        = "quantum",
  $keystone_password    = "ChangeMe",

  $rabbit_host          = "localhost",
  $rabbit_port          = "5672",
  $rabbit_user          = "guest",
  $rabbit_password      = "guest",
  $rabbit_virtual_host  = "/",

  $control_exchange     = "quantum",

  $core_plugin            = "quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPluginV2",
  $mac_generation_retries = 16,
  $dhcp_lease_duration    = 120
) {
  include quantum::params

  validate_re($sql_connection, '(sqlite|mysql|posgres):\/\/(\S+:\S+@\S+\/\S+)?')

  Package['quantum'] -> Quantum_config<||>

  if ($sql_connection =~ /mysql:\/\/\S+:\S+@\S+\/\S+/) {
    ensure_resource( 'package', 'python-mysqldb', {'ensure' => 'present'})
  } elsif ($sql_connection =~ /postgresql:\/\/\S+:\S+@\S+\/\S+/) {
    ensure_resource( 'package', 'python-psycopg2', {'ensure' => 'present'})
  } elsif($sql_connection =~ /sqlite:\/\//) {
    ensure_resource( 'package', 'python-pysqlite2', {'ensure' => 'present'})
  } else {
    fail("Invalid db connection ${sql_connection}")
  }

  file {"/etc/quantum":
    ensure  => directory,
    owner   => "quantum",
    group   => "root",
    mode    => 770,
    require => Package["quantum"]
  }

  package {"quantum":
    name   => $::quantum::params::package_name,
    ensure => $package_ensure
  }

  quantum_config {
    "DEFAULT/verbose":    value => $log_verbose;
    "DEFAULT/debug":      value => $log_debug;

    "DEFAULT/bind_host":  value => $bind_host;
    "DEFAULT/bind_port":  value => $bind_port;

    "DEFAULT/sql_connection":       value => $sql_connection;

    "DEFAULT/auth_strategy":        value => $auth_strategy;

    "DEFAULT/rabbit_host":          value => $rabbit_host;
    "DEFAULT/rabbit_port":          value => $rabbit_port;
    "DEFAULT/rabbit_userid":          value => $rabbit_user;
    "DEFAULT/rabbit_password":      value => $rabbit_password;
    "DEFAULT/rabbit_virtual_host":  value => $rabbit_virtual_host;

    "DEFAULT/control_exchange":     value => $control_exchange;

    "DEFAULT/core_plugin":            value => $core_plugin;
    "DEFAULT/mac_generation_retries": value => $mac_generation_retries;
    "DEFAULT/dhcp_lease_duration":    value => $dhcp_lease_duration;
  }
  require 'keystone::python'

  Package["quantum-server"] -> Quantum_api_config<||>
  Quantum_config<||> ~> Service["quantum-server"]
  Quantum_api_config<||> ~> Service["quantum-server"]

 # quantum_config {
 #   "DEFAULT/log_file":  value => $log_file
 # }

  quantum_api_config {
    "filter:authtoken/auth_host": value => $auth_host;
    "filter:authtoken/auth_port": value => $auth_port;
    "filter:authtoken/auth_uri": value => $auth_uri;
    "filter:authtoken/admin_tenant_name": value => $keystone_tenant;
    "filter:authtoken/admin_user": value => $keystone_user;
    "filter:authtoken/admin_password": value => $keystone_password;
  }

  if $enabled {
    $service_ensure = "running"
  } else {
    $service_ensure = "stopped"
  }

  package {"quantum-server":
    name   => $::quantum::params::server_package,
    ensure => $package_ensure
  }

  service {"quantum-server":
    name       => $::quantum::params::server_service,
    ensure     => $service_ensure,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true
  }

}
