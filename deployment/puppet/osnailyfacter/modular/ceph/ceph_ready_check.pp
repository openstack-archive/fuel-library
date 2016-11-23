notice('MODULAR: ceph_ready_check.pp')

# TODO:(mmalchuk) Rewrite this to use custom puppet function instead of the exec

$ceph_ready_check = '/etc/puppet/modules/osnailyfacter/modular/ceph/ceph_ready_check.rb'

exec { 'ceph_ready_check' :
  command   => "ruby $ceph_ready_check",
  path      => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
  logoutput => true,
}

class { '::osnailyfacter::override_resources': }
