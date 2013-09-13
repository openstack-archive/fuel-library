#
class ceph::ssh{

  $ssh_private_key = 'puppet:///modules/ceph/openstack'
  $ssh_public_key = 'puppet:///modules/ceph/openstack.pub'

  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0400',
  }

  file { '/root/.ssh':
    ensure => directory,
    mode   => '0700',
  }
  #file { '/root/.ssh/authorized_keys':
  #  source => $ssh_public_key,
  #}
  ssh_authorized_key {'ceph-ssh-key':
    ensure => present,
    key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAnHMPz2XBZSiPoIeTcagq5fuuvOH393szgx+Qp6Ue97VUu1l/13WNTHeYpwrvtZSgdag6AGygyeGjcZwZLOXDyIMY0xIMsAA/0te+tbhuL80wUzVGtuBE73JBz0+NBxiiwJFeOEfalblS/Oa1XhMhnifMSbtyOvGLocIJjUKcE29XNPIyiwWGBl5YaxYMAQimgZtrrIrOl/lVgWT434Io6B24OwXiB8tC+puN/S0phpxK9m+k1tNGQRCaSlL060hhg9EnSzcTjJ3xHVkYNJUchtHJmZ/zjCQUJK8NPxSw9efRk4/lGrST/7/rGkr+Vycj/Ll4GFIvCAmFSx1Q7No7IQ==',
    type   => 'ssh-rsa',
    user   => 'root',
  }
  file { '/root/.ssh/id_rsa':
    source => $ssh_private_key,
  }
  file { '/root/.ssh/id_rsa.pub':
    source => $ssh_public_key,
  }
  file { '/etc/ssh/ssh_config':
    mode    => '0600',
    content => 'Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null\n',
  }
}
