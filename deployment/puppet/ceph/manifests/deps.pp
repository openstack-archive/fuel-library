class ceph::deps (
  $type = 'base'
){
  
  package { ['ceph', 'redhat-lsb-core','ceph-deploy', 'python-pushy']:
    ensure => latest,
  }

  file {'/etc/sudoers.d/ceph':
    content => "#This is required for ceph-deploy\nDefaults !requiretty\n"
  }
  if $type == 'mon' {
    firewall {'010 ceph-mon allow':
      chain => 'INPUT',
      dport => 6789,
      proto => 'tcp',
      action  => accept,
    } 
  }

  #TODO: These should only except traffic on the storage network 
  if $type == 'osd' {
    firewall {'011 ceph-osd allow':
      chain => 'INPUT',
      dport => '6800-7100',
      proto => 'tcp',
      action  => accept,
    }
  }
 
}