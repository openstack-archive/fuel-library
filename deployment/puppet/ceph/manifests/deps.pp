class ceph::deps (
  $type = 'base'
){
  
  package { ['ceph', 'redhat-lsb-core','ceph-deploy', 'python-pushy']:
    ensure => latest,
  }

  file {'/etc/sudoers.d/ceph':
    content => "#This is required for ceph-deploy\nDefaults !requiretty\n"
  }
}