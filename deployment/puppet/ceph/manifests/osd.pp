#Ceph::osd will prepare and online devices in $::ceph::osd_devices
class ceph::osd (
  $devices = join(prefix($::ceph::osd_devices, "${::hostname}:"), " "),
){
 if ! empty($::ceph::osd_devices) {

  firewall {'011 ceph-osd allow':
    chain   => 'INPUT',
    dport   => '6800-7100',
    proto   => 'tcp',
    action  => accept,
  }

  exec { 'ceph-deploy osd prepare':
    #ceph-deploy osd prepare is ensuring there is a filesystem on the
    # disk according to the args passed to ceph.conf (above).
    #timeout: It has a long timeout because of the format taking forever.
    # A resonable amount of time would be around 300 times the length
    # of $osd_nodes. Right now its 0 to prevent puppet from aborting it.
    command   => "ceph-deploy osd prepare ${devices}",
    returns   => 0,
    timeout   => 0, #TODO: make this something reasonable
    tries     => 2,  #This is necessary because of race for mon creating keys
    try_sleep => 1,
    require   => [Exec['ceph-deploy init config'],
                  Firewall['011 ceph-osd allow'],
                 ],
    logoutput => true,
  }
  exec { 'ceph-deploy osd activate':
    command   => "ceph-deploy osd activate ${devices}",
    returns   => 0,
    require   => Exec['ceph-deploy osd prepare'],
    logoutput => true,
  }
 }
}