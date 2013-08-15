class ceph::ssh{
  package {['openssh-server', 'openssh-client']:
    ensure => latest
  }
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
  file { '/root/.ssh/authorized_keys':
    source => $ssh_public_key,
  }
  file { '/root/.ssh/id_rsa':
    source => $ssh_private_key,
  }
  file { '/root/.ssh/id_rsa.pub':
    source => $ssh_public_key,
  }
  file { '/etc/ssh/ssh_config':
    mode    => '0600',
    content => "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null\n",
  }
}
