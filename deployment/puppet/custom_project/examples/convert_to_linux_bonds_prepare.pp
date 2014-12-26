# This manifest will only prepare config files and convert
# script in /root/ifcfg directory, but it will not run it.

$fuel_settings = parseyaml($astute_settings_yaml)

# Customization for a project
$mgmt_vlan = inline_template("<%= begin @fuel_settings['network_scheme']['transformations'].select{|n| n['action'] == 'add-patch' and n['bridges'][1] == 'br-mgmt'}.first['tags'][0] rescue 'fail' end %>")
$storage_vlan = inline_template("<%= begin @fuel_settings['network_scheme']['transformations'].select{|n| n['action'] == 'add-patch' and n['bridges'][1] == 'br-storage'}.first['tags'][0] rescue 'fail' end %>")
$ext_vlan = inline_template("<%= begin @fuel_settings['network_scheme']['transformations'].select{|n| n['action'] == 'add-patch' and n['bridges'][1] == 'br-ex'}.first['tags'][0] rescue 'fail' end %>")
$bond0_interfaces = inline_template("<%= begin @fuel_settings['network_scheme']['transformations'].find{|n| n['action'] == 'add-bond' and n['bridge'] == 'br-ovs-bond0'}['interfaces'].join(' ') rescue 'fail' end %>")
$bond0_properties = inline_template("<%= begin @fuel_settings['network_scheme']['transformations'].find{|n| n['action'] == 'add-bond' and n['bridge'] == 'br-ovs-bond0'}['properties'].join(' ') rescue 'fail' end %>")

if (
  $::osfamily == 'RedHat' and
  is_hash($::fuel_settings['quantum_settings']) and
  $::fuel_settings['quantum_settings']['L2']['segmentation_type'] == 'gre' and
  $mgmt_vlan != 'fail' and
  $storage_vlan != 'fail' and
  $ext_vlan != 'fail' and
  $bond0_interfaces != 'fail' and
  $bond0_properties =~ /lacp=active/ and
  $bond0_properties =~ /bond_mode=balance-tcp/
){
  class {'custom_project::convert_to_linux_bonds':
    network_scheme => $::fuel_settings['network_scheme'],
    role           => $::fuel_settings['role'],
    run_exec       => false,
    mgmt_vlan      => $mgmt_vlan,
    storage_vlan   => $storage_vlan,
    ext_vlan       => $ext_vlan,
    mtu            => '9000',
  }
} else {
  warning('Your environment is not supported')
}
