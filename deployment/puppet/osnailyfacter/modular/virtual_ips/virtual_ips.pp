notice('MODULAR: virtual_ips.pp')

$network_metadata = hiera_hash('network_metadata')
$network_scheme = hiera_hash('network_scheme')
$role = hiera('role')

$default_vips_iptables_rules = { 'vrouter_pub' =>
                                  {'iptables_rules' => { 'start' => ['iptables -t nat -A POSTROUTING -o NS_VETH -j MASQUERADE'],
                                                          'stop'  => ['iptables -t nat -D POSTROUTING -o NS_VETH -j MASQUERADE'] }}}

generate_vips($network_metadata, $role, $network_scheme, $default_vips_iptables_rules)
