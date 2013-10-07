# configure apt sources for Ceph
class ceph::apt (
  $release = 'cuttlefish'
) {
  apt::key { 'ceph':
    key        => '17ED316D',
    key_source => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
    require    => Class['ceph::ssh']
  }
  apt::key { 'radosgw':
    key     => '6EAEAE2203C3951A',
    require => Class['ceph::ssh']  
  }
  Apt::Source {
    require => Apt::Key['ceph', 'radosgw'],
    release => $::lsbdistcodename,
    before  => Package['ceph'],
  }
  apt::source { 'ceph':
    location => "http://ceph.com/debian-${release}/",
  }
  apt::source { 'radosgw-apache2':
    location => 'http://gitbuilder.ceph.com/apache2-deb-precise-x86_64-basic/ref/master/',
  }
  apt::source { 'radosgw-fastcgi':
    location => 'http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-precise-x86_64-basic/ref/master/',
  }
}
