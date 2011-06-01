#
# TODO - this is currently hardcoded to be a xenserver

#
# this will be specific to how rackspace composes 
#  the various backends for openstack
#
class nova::rackspace::all(
  $logdir,
  $verbose,
  $sql_connection,
  $network_manager,
  $image_service,
  $flat_network_bridge = 'xenbr0',
  $glance_host,
  $glance_port,
  $allow_admin_api = 'true',
  $rabbit_host,
  $rabbit_password,
  $rabbit_port,
  $rabbit_userid,
  $rabbit_virtual_host,
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
  $quota_max_injected_file_path_bytes,
  $host,
  $compute_type = 'xenserver',
# do kvm and libvirt have extra config options?
  $xenapi_connection_url,
  $xenapi_connection_username,
  $xenapi_connection_password,
  $xenapi_inject_image = 'false'
) {


  # this is rackspace specific stuff for setting up the repos
  # most of this code may go away after they are finished
  # developing
  stage { 'repo-setup':
    before => Stage['main'],
  }
  class { 'apt':
    disable_keys => true,
    #always_apt_update => true,
    stage => 'repo-setup',
  }
  class { 'nova::rackspace::repo':
   stage => 'repo-setup',
  }
  class { 'mysql::server':
    root_password => 'password'
  }

  class { 'nova::rackspace::dev':}

  class { "nova":
    logdir               => $logdir,
    verbose              => $verbose,
    sql_connection       => $sql_connection,
    network_manager      => $network_manager,
    image_service        => $image_service,
    flat_network_bridge  => $flat_network_bridge,
    glance_host          => $glance_host,
    glance_port          => $glance_port,
    allow_admin_api      => $allow_admin_api,
    rabbit_host          => $rabbit_host,
    rabbit_password      => $rabbit_password,
    rabbit_port          => $rabbit_port,
    rabbit_userid        => $rabbit_userid,
    rabbit_virtual_host  => $rabbit_virtual_host,
    state_path           => $state_path,
    lock_path            => $lock_path,
    service_down_time    => $service_down_time,
    quota_instances      => $quota_instances,
    quota_cores          => $quota_cores,
    quota_volumes        => $quota_volumes,
    quota_gigabytes      => $quota_gigabytes,
    quota_floating_ips   => $quota_floating_ips,
    quota_metadata_items => $quota_metadata_items,
    quota_max_injected_files              => $quota_max_injected_files,
    quota_max_injected_file_content_bytes => $quota_max_injected_file_content_bytes,
    quota_max_injected_file_path_bytes    => $quota_max_injected_file_path_bytes,
  }

  class { "nova::api": enabled => false }
  class { "nova::compute::xenserver":
    host                       => $host,
    xenapi_connection_url      => $xenapi_connection_url,
    xenapi_connection_username => $xenapi_connection_username,
    xenapi_connection_password => $xenapi_connection_password,
    xenapi_inject_image        => $xenapi_inject_image,
    enabled                    => false
  }
  class { "nova::network": enabled => false }
  class { "nova::objectstore": enabled => false }
  class { "nova::scheduler": enabled => false }
  class { 'nova::db':
    # pass in db config as params
    password => 'password',
    name     => 'nova',
    user     => 'nova',
    host     => 'localhost',
  }
}
