class osnailyfacter::ntp::ntp_client {

  notice('MODULAR: ntp/ntp_client.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $management_vrouter_vip  = hiera('management_vrouter_vip')
  $ntp_servers             = hiera_array('ntp_servers', [$management_vrouter_vip])

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }
  if ! roles_include(['primary-controller', 'controller']) {
    class { '::ntp':
      servers         => $ntp_servers,
      service_ensure  => 'running',
      service_enable  => true,
      disable_monitor => true,
      iburst_enable   => true,
      tinker          => true,
      panic           => '0',
      stepout         => '5',
      minpoll         => '3',
    }

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

}
