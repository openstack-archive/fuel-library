notice('MODULAR: ntp-server.pp')

$ntp_servers = hiera('external_ntp')

class { 'ntp':
  servers         => strip(split($ntp_servers['ntp_list'], ',')),
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

class { 'cluster::ntp_ocf': }

if $::operatingsystem == 'Ubuntu' {
  include ntp::params
  tweaks::ubuntu_service_override { 'ntpd':
    package_name => $ntp::params::package_name,
    service_name => $ntp::params::service_name,
  }
}
