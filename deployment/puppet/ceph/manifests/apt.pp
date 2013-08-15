class ceph::apt (
  $release = 'cuttlefish'
) {
  apt::key { 'ceph':
    key        => '17ED316D',
    key_source => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
    require    => Class['ceph::ssh']
  }
  apt::source { 'ceph':
    location => "http://ceph.com/debian-${release}/",
    release  => $::lsbdistcodename,
    require  => Apt::Key['ceph'],
    before   => Package['ceph'],
  }
}
