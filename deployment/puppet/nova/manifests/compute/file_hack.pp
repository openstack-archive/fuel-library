#
# This is a temporary manifest that patches
# nova compute to resolve the folowing issue:
#   https://bugs.launchpad.net/ubuntu/+source/libvirt/+bug/996840
#
# This is only intended as a temporary fix and needs to be removed
# once the issue is resolved with upstream.
#
# TODO - check if this is still required for folsom
#
#
class nova::compute::file_hack() {

  # this only works on Ubunty

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '755',
    require => Package['nova-compute'],
    notify  => Service['nova-compute'],
  }

  file { '/usr/lib/python2.7/dist-packages/nova/virt/libvirt/connection.py': 
    source => 'puppet:///modules/nova/connection.py',
  }

  file { '/usr/lib/python2.7/dist-packages/nova/rootwrap/compute.py':
    source => 'puppet:///modules/nova/compute.py',
  }
}
