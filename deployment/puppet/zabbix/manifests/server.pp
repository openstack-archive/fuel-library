class zabbix::server(
  $db_ip,
  $primary_controller = false,
  $db_password = 'zabbix',
  $ocf_scripts_dir = '/usr/lib/ocf/resource.d',
  $ocf_scripts_provider = 'mirantis',
) {

  include zabbix::params

  file { '/etc/dbconfig-common':
    ensure    => directory,
    owner     => 'root',
    group     => 'root',
    mode      => '0755',
  }

  file { '/etc/dbconfig-common/zabbix-server-mysql.conf':
    require   => File['/etc/dbconfig-common'],
    ensure    => present,
    mode      => '0600',
    source    => 'puppet:///modules/zabbix/zabbix-server-mysql.conf',
  }

  package { $zabbix::params::server_pkg:
    require   => File['/etc/dbconfig-common/zabbix-server-mysql.conf'],
    ensure    => present,
  }

  file { $zabbix::params::server_config:
    ensure    => present,
    require   => Package[$zabbix::params::server_pkg],
    content   => template($zabbix::params::server_config_template),
  }

  class { 'zabbix::db':
    db_ip            => $db_ip,
    db_password      => $db_password,
    sync_db          => $primary_controller,
  }

  anchor { 'zabbix_db_start': } -> Class['zabbix::db'] -> File[$zabbix::params::server_config] -> anchor { 'zabbix_db_end': }

  if $::fuel_settings["deployment_mode"] == "multinode" {
    service { $zabbix::params::server_service:
      enable     => true,
      ensure     => running,
      require    => File[$zabbix::params::server_config],
      subscribe  => File[$zabbix::params::server_config],
    }

    File[$zabbix::params::server_config] -> Service[$zabbix::params::server_service]

 } else {
   if $::fuel_settings["role"] == "primary-controller" {
     cs_resource { "p_${zabbix::params::server_service}":
       primitive_class => 'ocf',
       provided_by     => $ocf_scripts_provider,
       primitive_type  => "${zabbix::params::server_service}",
       operations      => {
         'monitor' => { 'interval' => '5s', 'timeout' => '30s' },
         'start'   => { 'interval' => '0', 'timeout' => '30s' }
       },
     }

     File[$zabbix::params::server_config] -> File['zabbix-server-ocf'] -> Cs_resource["p_${zabbix::params::server_service}"]
     Cs_resource["p_${zabbix::params::server_service}"] -> Service["${zabbix::params::server_service}-started"]

   }
   file { 'zabbix-server-ocf' :
     ensure  => present,
     path    => "${ocf_scripts_dir}/${ocf_scripts_provider}/${zabbix::params::server_service}",
     mode    => '0755',
     owner   => 'root',
     group   => 'root',
     source  => 'puppet:///modules/zabbix/zabbix-server.ocf',
   }
   service { "${zabbix::params::server_service}-init-stopped":
     name       => $zabbix::params::server_service,
     enable     => false,
     ensure     => 'stopped',
     require    => File[$zabbix::params::server_config],
   }
   service { "${zabbix::params::server_service}-started":
     name       => "p_${zabbix::params::server_service}",
     enable     => true,
     ensure     => running,
     provider   => 'pacemaker',
   }

   File['zabbix-server-ocf'] -> Service["${zabbix::params::server_service}-init-stopped"] -> Service["${zabbix::params::server_service}-started"]
   File[$zabbix::params::server_config] -> Service["${zabbix::params::server_service}-started"]

 }

  if $zabbix::params::frontend {
    Anchor<| title == 'zabbix_db_end' |> -> Anchor<| title == 'zabbix_frontend_start' |>

    class { 'zabbix::frontend':
      require => Package[$zabbix::params::server_pkg],
    }

    anchor { 'zabbix_frontend_start': } -> Class['zabbix::frontend'] -> anchor { 'zabbix_frontend_end': }
  }

  if $::fuel_settings["deployment_mode"] != "multinode" {
    Anchor<| title == 'zabbix_frontend_end' |> -> Anchor<| title == 'zabbix_haproxy_start' |>

    class { 'zabbix::ha::haproxy': }

    anchor { 'zabbix_haproxy_start': } -> Class['zabbix::ha::haproxy'] -> anchor { 'zabbix_haproxy_end': }
  }

  firewall { '997 zabbix server':
    proto     => 'tcp',
    action    => 'accept',
    port      => $zabbix::ports['backend_server'] ? { unset=>$zabbix::ports['server'], default=>$zabbix::ports['backend_server'] },
  }

}
