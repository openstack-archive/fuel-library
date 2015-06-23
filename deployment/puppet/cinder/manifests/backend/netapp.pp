# == define: cinder::backend::netapp
#
# Configures Cinder to use the NetApp unified volume driver
# Compatible for multiple backends
#
# === Parameters
#
# [*netapp_login*]
#   (required) Administrative user account name used to access the storage
#   system or proxy server.
#
# [*netapp_password*]
#   (required) Password for the administrative user account specified in the
#   netapp_login option.
#
# [*netapp_server_hostname*]
#   (required) The hostname (or IP address) for the storage system or proxy
#   server.
#
# [*netapp_server_port*]
#   (optional) The TCP port to use for communication with the storage
#   system or proxy. If not specified, Data ONTAP drivers will use 80
#   for HTTP and 443 for HTTPS; E-Series will use 8080 for HTTP and
#   8443 for HTTPS.
#   Defaults to 80
#
# [*netapp_size_multiplier*]
#   (optional) The quantity to be multiplied by the requested volume size to
#   ensure enough space is available on the virtual storage server (Vserver) to
#   fulfill the volume creation request.
#   Defaults to 1.2
#
# [*netapp_storage_family*]
#   (optional) The storage family type used on the storage system; valid values
#   are ontap_7mode for using Data ONTAP operating in 7-Mode, ontap_cluster
#   for using clustered Data ONTAP, or eseries for NetApp E-Series.
#   Defaults to ontap_cluster
#
# [*netapp_storage_protocol*]
#   (optional) The storage protocol to be used on the data path with the storage
#   system. Valid values are iscsi, fc, nfs.
#   Defaults to nfs
#
# [*netapp_transport_type*]
#   (optional) The transport protocol used when communicating with the storage
#   system or proxy server. Valid values are http or https.
#   Defaults to http
#
# [*netapp_vfiler*]
#   (optional) The vFiler unit on which provisioning of block storage volumes
#   will be done. This parameter is only used by the driver when connecting to
#   an instance with a storage family of Data ONTAP operating in 7-Mode. Only
#   use this parameter when utilizing the MultiStore feature on the NetApp
#   storage system.
#   Defaults to undef
#
# [*netapp_volume_list*]
#   (optional) This parameter is only utilized when the storage protocol is
#   configured to use iSCSI or FC. This parameter is used to restrict
#   provisioning to the specified controller volumes. Specify the value of
#   this parameter to be a comma separated list of NetApp controller volume
#   names to be used for provisioning.
#   Defaults to undef
#
# [*netapp_vserver*]
#   (optional) This option specifies the virtual storage server (Vserver)
#   name on the storage cluster on which provisioning of block storage volumes
#   should occur.
#   Defaults to undef
#
# [*netapp_partner_backend_name*]
#   (optional) The name of the config.conf stanza for a Data ONTAP (7-mode)
#   HA partner.  This option is only used by the driver when connecting to an
#   instance with a storage family of Data ONTAP operating in 7-Mode, and it is
#   required if the storage protocol selected is FC.
#   Defaults to undef
#
# [*expiry_thres_minutes*]
#   (optional) This parameter specifies the threshold for last access time for
#   images in the NFS image cache. When a cache cleaning cycle begins, images
#   in the cache that have not been accessed in the last M minutes, where M is
#   the value of this parameter, will be deleted from the cache to create free
#   space on the NFS share.
#   Defaults to 720
#
# [*thres_avl_size_perc_start*]
#   (optional) If the percentage of available space for an NFS share has
#   dropped below the value specified by this parameter, the NFS image cache
#   will be cleaned.
#   Defaults to 20
#
# [*thres_avl_size_perc_stop*]
#   (optional) When the percentage of available space on an NFS share has
#   reached the percentage specified by this parameter, the driver will stop
#   clearing files from the NFS image cache that have not been accessed in the
#   last M minutes, where M is the value of the expiry_thres_minutes parameter.
#   Defaults to 60
#
# [*nfs_shares*]
#   (optional) Array of NFS exports in the form of host:/share; will be written into
#    file specified in nfs_shares_config
#    Defaults to undef
#
# [*nfs_shares_config*]
#   (optional) File with the list of available NFS shares
#   Defaults to '/etc/cinder/shares.conf'
#
# [*nfs_mount_options*]
#   (optional) Mount options passed to the nfs client. See section
#   of the nfs man page for details.
#   Defaults to undef
#
# [*netapp_copyoffload_tool_path*]
#   (optional) This option specifies the path of the NetApp Copy Offload tool
#   binary. Ensure that the binary has execute permissions set which allow the
#   effective user of the cinder-volume process to execute the file.
#   Defaults to undef
#
# [*netapp_controller_ips*]
#   (optional) This option is only utilized when the storage family is
#   configured to eseries. This option is used to restrict provisioning to the
#   specified controllers. Specify the value of this option to be a comma
#   separated list of controller hostnames or IP addresses to be used for
#   provisioning.
#   Defaults to undef
#
# [*netapp_sa_password*]
#   (optional) Password for the NetApp E-Series storage array.
#   Defaults to undef
#
# [*netapp_storage_pools*]
#   (optional) This option is used to restrict provisioning to the specified
#   storage pools. Only dynamic disk pools are currently supported. Specify the
#   value of this option to be a comma separated list of disk pool names to be
#   used for provisioning.
#   Defaults to undef
#
# [*netapp_eseries_host_type*]
#   (optional) This option is used to define how the controllers in the
#   E-Series storage array will work with the particular operating system on
#   the hosts that are connected to it.
#   Defaults to 'linux_dm_mp'
#
# [*netapp_webservice_path*]
#   (optional) This option is used to specify the path to the E-Series proxy
#   application on a proxy server. The value is combined with the value of the
#   netapp_transport_type, netapp_server_hostname, and netapp_server_port
#   options to create the URL used by the driver to connect to the proxy
#   application.
#   Defaults to '/devmgr/v2'
#
# [*extra_options*]
#   (optional) Hash of extra options to pass to the backend stanza
#   Defaults to: {}
#   Example :
#     { 'netapp_backend/param1' => { 'value' => value1 } }
#
# === Examples
#
#  cinder::backend::netapp { 'myBackend':
#    netapp_login           => 'clusterAdmin',
#    netapp_password        => 'password',
#    netapp_server_hostname => 'netapp.mycorp.com',
#    netapp_server_port     => '443',
#    netapp_transport_type  => 'https',
#    netapp_vserver         => 'openstack-vserver',
#  }
#
# === Authors
#
# Bob Callaway <bob.callaway@netapp.com>
#
# === Copyright
#
# Copyright 2014 NetApp, Inc.
#
define cinder::backend::netapp (
  $netapp_login,
  $netapp_password,
  $netapp_server_hostname,
  $volume_backend_name          = $name,
  $netapp_server_port           = '80',
  $netapp_size_multiplier       = '1.2',
  $netapp_storage_family        = 'ontap_cluster',
  $netapp_storage_protocol      = 'nfs',
  $netapp_transport_type        = 'http',
  $netapp_vfiler                = undef,
  $netapp_volume_list           = undef,
  $netapp_vserver               = undef,
  $netapp_partner_backend_name  = undef,
  $expiry_thres_minutes         = '720',
  $thres_avl_size_perc_start    = '20',
  $thres_avl_size_perc_stop     = '60',
  $nfs_shares                   = undef,
  $nfs_shares_config            = '/etc/cinder/shares.conf',
  $nfs_mount_options            = undef,
  $netapp_copyoffload_tool_path = undef,
  $netapp_controller_ips        = undef,
  $netapp_sa_password           = undef,
  $netapp_storage_pools         = undef,
  $netapp_eseries_host_type     = 'linux_dm_mp',
  $netapp_webservice_path       = '/devmgr/v2',
  $extra_options                = {},
) {

  if $nfs_shares {
    validate_array($nfs_shares)
    file {$nfs_shares_config:
      content => join($nfs_shares, "\n"),
      require => Package['cinder'],
      notify  => Service['cinder-volume']
    }
  }

  if $nfs_mount_options {
    cinder_config {
      "${name}/nfs_mount_options": value => $nfs_mount_options;
    }
  } else {
    cinder_config {
      "${name}/nfs_mount_options": ensure => absent;
    }
  }

  cinder_config {
    "${name}/volume_backend_name":          value => $volume_backend_name;
    "${name}/volume_driver":                value => 'cinder.volume.drivers.netapp.common.NetAppDriver';
    "${name}/netapp_login":                 value => $netapp_login;
    "${name}/netapp_password":              value => $netapp_password, secret => true;
    "${name}/netapp_server_hostname":       value => $netapp_server_hostname;
    "${name}/netapp_server_port":           value => $netapp_server_port;
    "${name}/netapp_size_multiplier":       value => $netapp_size_multiplier;
    "${name}/netapp_storage_family":        value => $netapp_storage_family;
    "${name}/netapp_storage_protocol":      value => $netapp_storage_protocol;
    "${name}/netapp_transport_type":        value => $netapp_transport_type;
    "${name}/netapp_vfiler":                value => $netapp_vfiler;
    "${name}/netapp_volume_list":           value => $netapp_volume_list;
    "${name}/netapp_vserver":               value => $netapp_vserver;
    "${name}/netapp_partner_backend_name":  value => $netapp_partner_backend_name;
    "${name}/expiry_thres_minutes":         value => $expiry_thres_minutes;
    "${name}/thres_avl_size_perc_start":    value => $thres_avl_size_perc_start;
    "${name}/thres_avl_size_perc_stop":     value => $thres_avl_size_perc_stop;
    "${name}/nfs_shares_config":            value => $nfs_shares_config;
    "${name}/netapp_copyoffload_tool_path": value => $netapp_copyoffload_tool_path;
    "${name}/netapp_controller_ips":        value => $netapp_controller_ips;
    "${name}/netapp_sa_password":           value => $netapp_sa_password, secret => true;
    "${name}/netapp_storage_pools":         value => $netapp_storage_pools;
    "${name}/netapp_eseries_host_type":     value => $netapp_eseries_host_type;
    "${name}/netapp_webservice_path":       value => $netapp_webservice_path;
  }

  if $netapp_storage_family == 'eseries' {
    cinder_config {
      "${name}/use_multipath_for_image_xfer": value => true;
    }
  }

  create_resources('cinder_config', $extra_options)

}
