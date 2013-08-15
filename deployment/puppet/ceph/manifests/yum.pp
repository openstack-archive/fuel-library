class ceph::rpm (
  $release = 'cuttlefish'
  )
{    
  yumrepo { 'ext-epel-6.8':
    descr      => 'External EPEL 6.8',
		name	     => 'ext-epel-6.8',
		baseurl	   => absent,
		gpgcheck   => '2',
		gpgkey	   => absent,
		mirrorlist => absent,
  }

  yumrepo { 'ext-ceph':
    descr      => 'External Ceph ${release}',
    name       => 'ext-ceph-${release}',
    baseurl    => 'http://ceph.com/rpm-${release}',
    gpgcheck   => '1',
    gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
    mirrorlist => absent,
  } 
}