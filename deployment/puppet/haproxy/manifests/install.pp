# Private class
class haproxy::install inherits haproxy {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  package { $package_name:
    ensure  => $_package_ensure,
    alias   => 'haproxy',
  }
}
