# == Class: corosync::cleanup
#
# Include this class to cleanup the corosync resource when there are changes in
# any of the native cs_* types. Useful for multi-node provisioning when the
# nodes are not always in a stable state after provisioning.
#
# === Examples
#
# cleanup corosync after making cluster configuration changes:
#
#   include corosync::cleanup
#
# === Copyright
#
# Copyright 2012 Puppet Labs, LLC.
#
define corosync::cleanup () {
  Cs_resource <| name == $name |> ~> Exec["crm resource cleanup $name"]

  ##FIXME: we need to create a better way to workaround crm commit <-> cleanup race condition than a simple sleep 

  exec { "crm resource cleanup $name":
    command     => "bash -c \"(sleep 5 && crm resource cleanup $name) || :\"",
    path        => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    returns     => [0,""],
    refreshonly => true,
    timeout     => 600,
  }
}
