class osnailyfacter::ntp::ntp_server {

  notice('MODULAR: ntp/ntp_server.pp')

  $ntp_servers = hiera('external_ntp')

  if is_array($ntp_servers['ntp_list']) {
    $external_ntp = $ntp_servers['ntp_list']
  } else {
    $external_ntp = strip(split($ntp_servers['ntp_list'], ','))
  }

  class { '::ntp':
    servers         => $external_ntp,
    service_enable  => true,
    service_ensure  => 'running',
    disable_monitor => true,
    iburst_enable   => true,
    tinker          => true,
    panic           => '0',
    stepout         => '5',
    minpoll         => '3',
    restrict        => [
          '-4 default kod nomodify notrap nopeer noquery',
          '-6 default kod nomodify notrap nopeer noquery',
          '127.0.0.1',
          '::1',
    ],
  }

  class { '::cluster::ntp_ocf': }

  if $::operatingsystem == 'Ubuntu' {
    include ::ntp::params

    # puppetlabs/ntp uses one element array as package_name default value
    if is_array($ntp::params::package_name) {
      $package_name = $ntp::params::package_name[0]
    } else {
      $package_name = $ntp::params::package_name
    }

    tweaks::ubuntu_service_override { 'ntpd':
      package_name => $package_name,
      service_name => $ntp::params::service_name,
    }
  }

}
