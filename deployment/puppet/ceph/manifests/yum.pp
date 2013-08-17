class ceph::yum (
  $release = 'cuttlefish'
  )
{    
  yumrepo { 'ext-epel-6.8':
    descr      => 'External EPEL 6.8',
		name	     => 'ext-epel-6.8',
		baseurl	   => absent,
		gpgcheck   => '0',
		gpgkey	   => absent,
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

}