#
class neutron::agents::l3 (
  $neutron_config     = {},
  $verbose          = false,
  $debug            = false,
  $interface_driver = 'neutron.agent.linux.interface.OVSInterfaceDriver',
  $service_provider = 'generic',
  $primary_controller = false
) {
  include 'neutron::params'

  Anchor<| title=='neutron-server-done' |> ->
  anchor {'neutron-l3': }
  Service<| title=='neutron-server' |> -> Anchor['neutron-l3']

  if $::neutron::params::l3_agent_package {
    $l3_agent_package = 'neutron-l3'

    package { 'neutron-l3':
      name   => $::neutron::params::l3_agent_package,
      ensure => present,
    }
    # do not move it to outside this IF
    Package['neutron-l3'] -> Neutron_l3_agent_config <| |>
  } else {
    $l3_agent_package = $::neutron::params::package_name
  }


  include 'neutron::waist_setup'

  Neutron_config <| |> -> Neutron_l3_agent_config <| |>

  neutron_l3_agent_config {
    'DEFAULT/debug':          value => $debug;
    'DEFAULT/verbose':        value => $verbose;
    'DEFAULT/router_id':     ensure => absent;
    'DEFAULT/handle_internal_only_routers': value => false;
    'DEFAULT/root_helper':    value => $neutron_config['root_helper'];
    'DEFAULT/auth_url':       value => $neutron_config['keystone']['auth_url'];
    'DEFAULT/admin_user':     value => $neutron_config['keystone']['admin_user'];
    'DEFAULT/admin_password': value => $neutron_config['keystone']['admin_password'];
    'DEFAULT/admin_tenant_name': value => $neutron_config['keystone']['admin_tenant_name'];
    'DEFAULT/interface_driver':  value => $interface_driver;
    'DEFAULT/metadata_ip':   value => $neutron_config['metadata']['metadata_ip'];
    'DEFAULT/metadata_port': value => $neutron_config['metadata']['metadata_port'];
    'DEFAULT/use_namespaces': value => $neutron_config['L3']['use_namespaces'];
    'DEFAULT/router_delete_namespaces': value => 'False';  # Neutron can't properly clean network namespace before delete.
    'DEFAULT/send_arp_for_ha': value => $neutron_config['L3']['send_arp_for_ha'];
    'DEFAULT/periodic_interval': value => $neutron_config['L3']['resync_interval'];
    'DEFAULT/periodic_fuzzy_delay': value => $neutron_config['L3']['resync_fuzzy_delay'];
    'DEFAULT/external_network_bridge': value => $neutron_config['L3']['public_bridge'];
  }

  Anchor['neutron-l3'] ->
    Neutron_l3_agent_config <| |> ->
              Anchor['neutron-l3-done']

  # rootwrap error with L3 agent
  # https://bugs.launchpad.net/neutron/+bug/1069966
  $iptables_manager = "/usr/lib/${::neutron::params::python_path}/neutron/agent/linux/iptables_manager.py"
  exec { 'patch-iptables-manager':
    command => "sed -i '272 s|/sbin/||' ${iptables_manager}",
    onlyif  => "sed -n '272p' ${iptables_manager} | grep -q '/sbin/'",
    path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
    require => [Anchor['neutron-l3'], Package[$l3_agent_package]],
  }

  anchor {'neutron-l3-cellar': }
  Anchor['neutron-l3-cellar'] -> Anchor['neutron-l3-done']
  anchor {'neutron-l3-done': }
  Anchor['neutron-l3'] -> Anchor['neutron-l3-done']
  if !defined(Service['neutron-l3']) {
    notify{ "Module ${module_name} cannot notify service neutron-l3 on package update": }
  }

}
