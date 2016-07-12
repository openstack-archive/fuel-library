class openstack_tasks::roles::controller {

  notice('MODULAR: roles/controller.pp')

  # Pulling hiera
  $primary_controller             = hiera('primary_controller')

  if $primary_controller {
    package { 'cirros-testvm' :
      ensure => 'installed',
      name   => 'cirros-testvm',
    }

    # create m1.micro flavor for OSTF
    $haproxy_stats_url       = "http://${management_vip}:10000/;csv"
    $nova_endpoint           = hiera('nova_endpoint', $management_vip)
    $nova_internal_protocol  = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'protocol', 'http')
    $nova_internal_endpoint  = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'hostname', [$nova_endpoint])
    $nova_url                = "${nova_internal_protocol}://${nova_internal_endpoint}:8774"

    $lb_defaults = { 'provider' => 'haproxy', 'url' => $haproxy_stats_url }

    if $external_lb {
      $lb_backend_provider = 'http'
      $lb_url = $nova_url
    }

    $lb_hash = {
      'nova-api' => {
        name     => 'nova-api',
        provider => $lb_backend_provider,
        url      => $lb_url
      }
    }

    ::osnailyfacter::wait_for_backend {'nova-api':
      lb_hash     => $lb_hash,
      lb_defaults => $lb_defaults
    }

    Openstack::Ha::Haproxy_service <| |> -> Haproxy_backend_status <| |>

    include ::osnailyfacter::wait_for_keystone_backends

    Class['::nova::api'] ->
      ::Osnailyfacter::Wait_for_backend['nova-api'] ->
        Nova_flavor['m1.micro']
    Class['::osnailyfacter::wait_for_keystone_backends']
      Nova_flavor['m1.micro']

    nova_flavor { 'm1.micro':
      ram     => 64,
      disk    => 0,
      vcpu    => 1,
    }
  }

  Exec { logoutput => true }

  # BP https://blueprints.launchpad.net/mos/+spec/include-openstackclient
  package { 'python-openstackclient' :
    ensure => installed,
  }

  # Reduce swapiness on controllers, see LP#1413702
  sysctl::value { 'vm.swappiness':
    value => '10'
  }

}
# vim: set ts=2 sw=2 et :
