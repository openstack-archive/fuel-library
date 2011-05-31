class nova(
  $verbose = false,
  $nodaemon = false,
  $logdir = '/var/log/nova',
  $sql_connection,
  $network_manager,
  $image_service,
  # is flat_network_bridge valid if network_manager is not FlatManager?
  $flat_network_bridge,
  $glance_host,
  $glance_port, # default is 9292
  $allow_admin_api,
  $rabbit_host,
  $rabbit_password,
  $rabbit_port,
  $rabbit_userid,
  $rabbit_virtual_host,
  # Following may need to be broken out to different nova services
  $state_path,
  $lock_path,
  $service_down_time,
  $quota_instances,
  $quota_cores,
  $quota_volumes,
  $quota_gigabytes,
  $quota_floating_ips,
  $quota_metadata_items,
  $quota_max_injected_files,
  $quota_max_injected_file_content_bytes,
  $quota_max_injected_file_path_bytes
) {

  class { 'puppet': }
  class {
    [
      'bzr',
      'git',
      'gcc',
      'extrapackages',
      # I may need to move python-mysqldb to elsewhere if it depends on mysql
      'python',
    ]:
  } 
  package { "python-greenlet": ensure => present }

  package { ["nova-common", "nova-doc"]:
    ensure => present,
    require => Package["python-greenlet"]
  }

  Nova_config<| |> { require +> Package["nova-common"] }
}
