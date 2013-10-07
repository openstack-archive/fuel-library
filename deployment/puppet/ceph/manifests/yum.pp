# configure yum repos for Ceph
class ceph::yum (
  $release = 'cuttlefish'
  )
{    
  yumrepo { 'ext-epel-6.8':
    descr      => 'External EPEL 6.8',
    name       => 'ext-epel-6.8',
    baseurl    => absent,
    gpgcheck   => '0',
    gpgkey     => absent,
    mirrorlist => 'https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
  }

  yumrepo { 'ext-ceph':
    descr      => "External Ceph ${release}",
    name       => "ext-ceph-${release}",
    baseurl    => "http://ceph.com/rpm-${release}/el6/\$basearch",
    gpgcheck   => '1',
    gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
    mirrorlist => absent,
  } 

  yumrepo { 'ext-ceph-noarch':
    descr      => 'External Ceph noarch',
    name       => "ext-ceph-${release}-noarch",
    baseurl    => "http://ceph.com/rpm-${release}/el6/noarch",
    gpgcheck   => '1',
    gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
    mirrorlist => absent,
  } 


  # Fuel repos
  yumrepo { 'centos-base':
      descr      => 'Mirantis-CentOS-Base',
      name       => 'base',
      baseurl    => 'http://download.mirantis.com/centos-6.4',
      gpgcheck   => '1',
      gpgkey     => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
      mirrorlist => absent,
  }

  yumrepo { 'openstack-epel-fuel-grizzly':
      descr      => 'Mirantis OpenStack grizzly Custom Packages',
      baseurl    => 'http://download.mirantis.com/epel-fuel-grizzly-3.1',
      gpgcheck   => '1',
      gpgkey     => 'http://download.mirantis.com/epel-fuel-grizzly-3.1/mirantis.key',
      mirrorlist => absent,
  }

  # completely disable additional out-of-box repos
  yumrepo { 'extras':
          descr      => 'CentOS-$releasever - Extras',
          mirrorlist => 'http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras',
          gpgcheck   => '1',
          baseurl    => absent,
          gpgkey     => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
          enabled    => '0',
  }

  yumrepo { 'updates':
          descr      => 'CentOS-$releasever - Updates',
          mirrorlist => 'http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates',
          gpgcheck   => '1',
          baseurl    => absent,
          gpgkey     => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
          enabled    => '0',
  }
}
