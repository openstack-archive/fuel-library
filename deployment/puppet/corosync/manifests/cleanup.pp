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
define corosync::cleanup (
  $force = false,
  $wait_before = 15
) {
  if $force   {
    Cs_resource <| name == $name |> ~> Exec["crm resource cleanup $name"]

    ##FIXME: we need to create a better way to workaround crm commit <-> cleanup race condition than a simple sleep 
    #Workaround for hostname bugs with FQDN vs short hostname
    exec { "crm resource cleanup $name":
      command     => "bash -c \"(sleep ${wait_before} && crm_resource --resource ${name}  --cleanup --node `uname -n`) || :\"",
      path        => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
      returns     => [0,""],
      refreshonly => true,
      timeout     => 600,
    }
  } 
} 
