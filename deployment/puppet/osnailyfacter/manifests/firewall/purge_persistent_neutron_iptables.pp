class osnailyfacter::firewall::purge_persistent_neutron_iptables {

  notice('MODULAR: firewall/purge_persistent_neutron_iptables.pp')

  remove_lines('/etc/iptables/rules.v4', '-A neutron-openvswi-.* -m set --match-set .* src -j RETURN')
}

