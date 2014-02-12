# HA for Ceph Monitors
#
# Full list of monitor nodes should be specified in ceph.conf for high
# availability of a Ceph cluster. This has to be specified after initial
# bootstrap of the cluster (i.e. after ceph service is started on the
# first monitor node).

class ceph::ha (
  $monitors = merge_arrays(
    filter_nodes($::fuel_settings['nodes'], 'role', 'primary-controller'),
    filter_nodes($::fuel_settings['nodes'], 'role', 'controller'),
    filter_nodes($::fuel_settings['nodes'], 'role', 'ceph-mon')
  ),
) {
  ceph_conf {
    'global/mon_host':            value => inline_template('<%= @monitors.map {|m| m["internal_address"] }.join(" ") %>');
    'global/mon_initial_members': value => inline_template('<%= @monitors.map {|m| m["name"] }.join(" ") %>');
  }
}
