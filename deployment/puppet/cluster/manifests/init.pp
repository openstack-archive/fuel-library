# == Class: cluster
#
# This module installs and configures the Pacemaker cluster services
#
class cluster (
  $cluster_nodes,
  $cluster_rrp_nodes        = undef,

  $no_quorum_policy         = 'ignore',
  $stonith_enabled          = false,
  $start_failure_is_fatal   = false,
  $symmetric_cluster        = false,
  $cluster_recheck_interval = '60',

  $cluster_user             = 'hacluster',
  $cluster_group            = 'haclient',
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
    cluster_user             => $cluster_user,
    cluster_group            => $cluster_group,
    plugin_version           => '1',
    log_file_path            => '/var/log/corosync.log',
  }

  Pacemaker_property {
    ensure => 'present',
  }

  pacemaker_property {
    'no-quorum-policy'         : value => $no_quorum_policy;
    'stonith-enabled'          : value => $stonith_enabled;
    'start-failure-is-fatal'   : value => $start_failure_is_fatal;
    'symmetric-cluster'        : value => $symmetric_cluster;
    'cluster-recheck-interval' : value => $cluster_recheck_interval;
  }

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  file { 'ocf-fuel-path' :
    ensure  => 'directory',
    path    => '/usr/lib/ocf/resource.d/fuel',
    recurse => true,
  }

  file { 'limits_conf' :
    ensure  => 'present',
    path    => '/etc/security/limits.conf',
    source  => 'puppet:///modules/openstack/limits.conf',
    replace => true,
  }

  # Sometimes during first start pacemaker can not connect to corosync
  # via IPC due to pacemaker and corosync processes are run under different users
  if $::operatingsystem == 'Ubuntu' {
    file { 'pcmk_uid_gid' :
      path    => '/etc/corosync/uidgid.d/pacemaker',
      content => "uidgid {\n  uid: ${cluster_user}\n  gid: ${cluster_group}\n}",
    }

    File['pcmk_uid_gid'] ->
    Class['pacemaker::new::service']
  }

  # pcmk_nodes { 'pacemaker' :
  #   nodes               => $corosync_nodes,
  #   add_pacemaker_nodes => false,
  # }

  Anchor['cluster-start'] ->
  File['ocf-fuel-path'] ->
  File['limits_conf'] ->
  Class['pacemaker::new'] ->
  Pacemaker_property <||> ->
  Anchor['cluster-end']

}
