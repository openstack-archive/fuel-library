#
# Configures dependencies that are common for all storage
# types.
#   - installs an rsync server
#   - installs required packages
#
# == Parameters
#  [*storeage_local_net_ip*] ip address that the swift servers should
#    bind to. Required.
# == Dependencies
#
# == Examples
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2011 Puppetlabs Inc, unless otherwise noted.
#
class swift::storage(
  $storage_local_net_ip
) {

  if !defined(Class['rsync::server']){
    class{ 'rsync::server':
      use_xinetd => true,
      address    => $storage_local_net_ip,
      use_chroot => 'no',
    }
  }
}
