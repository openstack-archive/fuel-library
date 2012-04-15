#vlan.pp
class nova::network::vlan (
  $enabled = true
) {
  class { 'nova::network':
    enabled => $enabled,
  }
}
