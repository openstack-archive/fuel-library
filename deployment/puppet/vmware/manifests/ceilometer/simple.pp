define vmware::ceilometer::simple (
  $index,
  $ceilometer_config   = '/etc/ceilometer/ceilometer.conf',
  $ceilometer_conf_dir = '/etc/ceilometer/ceilometer-compute.d',
) {
  if ! defined(File["${ceilometer_conf_dir}"]) {
    file { $ceilometer_conf_dir:
      ensure => directory,
      owner  => 'ceilometer',
      group  => 'ceilometer',
      mode   => '0750'
    }
  }

  $ceilometer_compute_conf = "${ceilometer_conf_dir}/vmware-${index}.conf"

  include ceilometer::params
  $ceilometer_compute_vmware = "${::ceilometer::params::agent_compute_service_name}-vmware"

  case $::osfamily {
    'RedHat': {
      $ceilometer_compute_vmware_init = "/etc/init.d/${ceilometer_compute_vmware}"

      if ! defined(File[$ceilometer_compute_vmware_init]) {
        file { $ceilometer_compute_vmware_init:
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
          source => 'puppet:///modules/vmware/ceilometer-compute-init-centos',
        }
      }

      $ceilometer_compute_default = "/etc/sysconfig/${ceilometer_compute_vmware}-${index}"
      if ! defined(File[$ceilometer_compute_default]) {
        file { $ceilometer_compute_default:
          ensure  => present,
          content => "OPTIONS='--config-file=${ceilometer_config} --config-file=${ceilometer_compute_conf}'",
        }
      }

      $init_link = "${ceilometer_compute_vmware_init}-${index}"
      if ! defined(File[$init_link]) {
        file { $init_link:
          ensure => link,
          target => "${ceilometer_compute_vmware_init}"
        }
      }

      $init_reload_cmd = '/bin/true'
    }
    'Debian': {
      $ceilometer_compute_default = "/etc/default/${ceilometer_compute_vmware}-${index}"
      if ! defined(File[$ceilometer_compute_default]) {
        file { $ceilometer_compute_default:
          ensure  => present,
          content => "CEILOMETER_COMPUTE_OPTS='--config-file=${ceilometer_config} --config-file=${ceilometer_compute_conf}'",
        }
      }

      $ceilometer_compute_vmware_init = "/etc/init/${ceilometer_compute_vmware}.conf"
      if ! defined(File[$ceilometer_compute_vmware_init]) {
        file { $ceilometer_compute_vmware_init:
          owner  => 'root',
          group  => 'root',
          mode   => '0644',
          source => 'puppet:///modules/vmware/ceilometer-compute-init-ubuntu',
        }
      }

      $init_link = "/etc/init/${ceilometer_compute_vmware}-${index}.conf"
      if ! defined(File[$init_link]) {
        file { $init_link:
          ensure => link,
          target => "${ceilometer_compute_vmware_init}"
        }
      }

      $upstart_link = "/etc/init.d/${ceilometer_compute_vmware}-${index}"
      if ! defined(File[$upstart_link]) {
        file { $upstart_link:
          ensure => link,
          target => '/etc/init.d/ceilometer-agent-compute'
        }
      }

      $init_reload_cmd = '/sbin/initctl reload-configuration'
    }
    default: {
      fail { "Unsupported OS family (${::osfamily})": }
    }
  }

  $cluster = $name
  if ! defined (File["${ceilometer_compute_conf}"]) {
    file { "${ceilometer_compute_conf}":
      ensure  => present,
      content => template('vmware/ceilometer-compute.conf.erb'),
      mode    => '0600',
      owner   => 'ceilometer',
      group   => 'ceilometer',
    }
  }

  $init_reload = 'initctl reload-configuration'
  if ! defined(Exec[$init_reload]) {
    exec { $init_reload:
      command => "${init_reload_cmd}",
      path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ]
    }
  }

  if ! defined(Service["ceilometer_compute_vmware_${index}"]) {
    service { "ceilometer_compute_vmware_${index}":
      ensure => running,
      name   => "${ceilometer_compute_vmware}-${index}",
      enable => true,
    }
  }

  File[$ceilometer_conf_dir]->
  File[$ceilometer_compute_conf]->
  File[$ceilometer_compute_vmware_init]->
  File[$ceilometer_compute_default]~>
  Exec[$init_reload]->
  Service["ceilometer_compute_vmware_${index}"]
}
