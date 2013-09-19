# Ceph::mds will install mds server if invoked

class ceph::mds (
) {
  if $::mds_server {
    exec { 'ceph-deploy mds create':
      command   => "ceph-deploy mds create ${::mds_server}",
      logoutput => true,
    }
  }
}
