## This is class includes services from Array
class nagios::common inherits nagios {

  nagios::host::hosts { $::hostname: }
  nagios::host::hostextinfo { $::hostname: }
  #nagios::host::hostgroups { $::hostname: }

  define runservice($service) {
    include nagios::params
    notify {$services_list[$service]:}
    nagios::service::services { $service:
      command => $services_list[$service]
    }
  }

  define addservice($services_count = size($services), $current = 0) {
    if $current == $services_count -1 {
      nagios::common::runservice { $services[$current]:
      service => $services[$current],
      }
    } else {
      $c_num = $current + 1

      nagios::common::addservice { $services[$current]:
        current => $c_num,
      }
      nagios::common::runservice { $services[$current]:
        service => $services[$current],
      }
    }
  }

  nagios::common::addservice { 'Add services': }

  if $::virtual == 'physical' {
    $a_disks = split($::disks, ',')
    nagios::service::services { $a_disks:
    }

    $a_interfaces = split($::interfaces, ',')
    nagios::service::services { $a_interfaces:
    }
  }
}
