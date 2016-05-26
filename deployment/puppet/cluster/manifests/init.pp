# == Class: cluster
#
# This module installs and configures the Pacemaker cluster services
#
class cluster (
  $cluster_nodes,
  $cluster_rrp_nodes,
) {

  anchor { 'cluster-start': }
  anchor { 'cluster-end': }

  class { 'pacemaker::new' :
    firewall_corosync_manage => false,
    firewall_pcsd_manage     => false,
    pcsd_mode                => false,
    cluster_auth_enabled     => false,
    cluster_nodes            => $cluster_nodes,
    cluster_rrp_nodes        => $cluster_rrp_nodes,
    cluster_name             => 'fuel',
    cluster_user             => 'hacluster',
    cluster_group            => 'haclinet',
    plugin_version           => '1',
    log_file_path            => '/var/log/corosync.log',
  }

}
