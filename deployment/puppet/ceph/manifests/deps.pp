class ceph::deps (
  $type = 'base'
){
  package { ['ceph', 'redhat-lsb-core','ceph-deploy', 'python-pushy']:
    ensure => latest,
  }
  file {'/usr/bin/ceph-deploy':
    source  => 'puppet:///modules/ceph/ceph-deploy',
    mode    => 0755,
    require => Package['ceph-deploy'],
    #This applies necessary patch from
    # https://github.com/ceph/ceph-deploy/pull/54
    #This can be removed if patch is present in the current package.
  }

  file {'/etc/sudoers.d/ceph':
    content => "#This is required for ceph-deploy\nDefaults !requiretty\n"
  }
}