# == Define: cluster::virtual_ip
#
# Configure VirtualIP resource for corosync/pacemaker.
#
# === Parameters
#
# [*name*]
#   Name of virtual IP resource
#
# [*vip*]
#   Specify dictionary of VIP parameters, ex:
#   {
#       nic    => 'eth0', 
#       ip     => '10.1.1.253'
#   }
#
define cluster::virtual_ip (
  $vip,
  $key = $name,
){
  $cib_name = "vip__${key}"
  $vip_name = "vip__${key}"

  cs_shadow { $cib_name: cib => $cib_name }
  cs_commit { $cib_name: cib => $cib_name }
  ::corosync::cleanup { $vip_name: }

  Cs_commit[$cib_name] -> ::Corosync::Cleanup[$vip_name]
  Cs_commit[$cib_name] ~> ::Corosync::Cleanup[$vip_name]

  cs_resource { $vip_name:
    ensure          => present,
    cib             => $cib_name,
    primitive_class => 'ocf',
    provided_by     => 'heartbeat',
    primitive_type  => 'IPaddr2',
    # multistate_hash => {
    #   'type' => 'clone',
    # },
    # ms_metadata => {
    #   'interleave' => 'true',
    # },
    parameters => {
      'nic'     => $vip[nic],
      'ip'      => $vip[ip],
      'iflabel' => $vip[iflabel] ? { undef => 'ka', default => $vip[iflabel] },
      #'lvs_support' => $vip[lvs_support] ? { undef => 'false', default => $vip[lvs_support] },
      #'unique_clone_address' => $vip[unique_clone_address] ? { undef => 'true', default => $vip[unique_clone_address] },
    },
    operations => {
      'monitor' => {
        'interval' => '2',
        'timeout'  => '30'
      },
      'start' => {
        'timeout' => '30'
      },
      'stop' => {
        'timeout' => '30'
      },
    },
  }
}

Class['corosync'] -> Cluster::Virtual_ip <||>
if defined(Corosync::Service['pacemaker']) {
  Corosync::Service['pacemaker'] -> Cluster::Virtual_ip <||>
}
#
###