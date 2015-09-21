notice('MODULAR: enable_edac.pp')


if ! ($::osfamily in [ 'Debian', 'RedHat' ]) {
  fail("unsupported osfamily ${::osfamily}, currently Debian and RedHat are the only supported platforms")
}

$modulename = "edac_core"
$modulesfile = $::osfamily ? { 'Debian' => "/etc/modules", 'RedHat' => "/etc/rc.modules" }

$insert_module_cmd = $::osfamily ? {
  'Debian' => "echo '${modulename}' >> '${modulesfile}'",
  'RedHat' => "echo 'modprobe ${modulename}' >> '${modulesfile}'"
}

$insert_unless_cmd = $::osfamily ? {
  'Debian' => "grep -qFx '${modulename}' '${modulesfile}'",
  'RedHat' => "grep -q '^modprobe ${modulename}\$' '${modulesfile}'"
}

exec { "insert_module_${modulename}":
  path    => '/sbin:/usr/bin:/usr/sbin:/bin',
  command => $insert_module_cmd,
  unless  => $insert_unless_cmd,
}

exec { "modprobe ${modulename}":
  path    => '/sbin:/usr/bin:/usr/sbin:/bin',
  command => "modprobe ${modulename}",
  unless  => "grep -q '^${modulename} ' '/proc/modules'"
}
