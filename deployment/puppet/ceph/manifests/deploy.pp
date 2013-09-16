#Ceph::deploy will install mds server if invoked
class ceph::deploy (
) {
  if $mds_server {
    exec { 'ceph-deploy-s4':
      command => "ceph-deploy mds create ${mds_server}",
      require => Class['c_osd'],
      logoutput => true,
    }
  }
}
