#Creates ML3 required default routes for interfaces to reply to
define l23network::l3::ip_rule_route (
  $interface,
  $ipaddr,
  $netmask,
  $gateway,
  $table
  ) {

  Exec {path  => '/bin:/usr/bin:/sbin:/usr/sbin'}

}
