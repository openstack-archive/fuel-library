class vswitch (
  $provider = "ovs"
) {
  $cls = "vswitch::$provider"
  include $cls
}
