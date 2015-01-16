# Private define
define haproxy::peer::collect_exported {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  Haproxy::Peer <<| peers_name == $name |>>
}
