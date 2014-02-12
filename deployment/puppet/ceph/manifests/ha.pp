# HA for Ceph Monitors
#
# Full list of monitor nodes should be specified in ceph.conf for high
# availability of a Ceph cluster.

class ceph::ha (
  $monitors = merge_arrays(
    filter_nodes($::fuel_settings['nodes'], 'role', 'primary-controller'),
    filter_nodes($::fuel_settings['nodes'], 'role', 'controller'),
    filter_nodes($::fuel_settings['nodes'], 'role', 'ceph-mon')
  ),
) {

  if $::fuel_settings['deployment_mode'] =~ /^ha/ {
    ceph_conf {
      'global/mon_host':            value => inline_template('<%= @monitors.map {|m| m["internal_address"] }.join(" ") %>');
      'global/mon_initial_members': value => inline_template('<%= @monitors.map {|m| m["name"] }.join(" ") %>');
    }

    if defined(Service['ceph']) {
      # has to be an exec: Puppet can't reload a service without
      # declaring an ordering relationship
      exec {'reload Ceph for HA':
        command   => 'service ceph reload',
        subscribe => [Ceph_conf['global/mon_host'], Ceph_conf['global/mon_initial_members']]
      }
    }
  }
}
