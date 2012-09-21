
class firewall (
	$ssh_port = 22,
	$http_port = 80,
	$https_port = 443,
	$mysql_port = 3306,
	$mysql_backend_port = 3307,
	$keystone_public_port =  5000,
        $keystone_admin_port = 35357,
	$glance_api_port = 9292,
	$glance_reg_port = 9191,
	$glance_nova_api_ec2_port = 8773,
	$nova_api_compute_port =   8774,
	$nova_api_metadata_port =  8775,
	$nova_api_volume_port =  8776,
	$nova_vncproxy_port =  6080,
	$erlang_epmd_port  =   4369,
	$erlang_rabbitmq_port =  5672,
	$memcached_port =  11211,
) {

  case $::osfamily {
    'RedHat': {
      firewall::allow {[
		$ssh_port,
		$http_port,
		$https_port,
		$mysql_port,
		$mysql_backend_port,
		$keystone_public_port,
		$keystone_admin_port, 
		$glance_api_port,
		$glance_reg_port,
		$glance_nova_api_ec2_port,
		$nova_api_compute_port,
		$nova_api_metadata_port,
		$nova_api_volume_port,
		$nova_vncproxy_port,
		$erlang_epmd_port,
		$erlang_rabbitmq_port,
		$memcached_port,
      ]: }
     }
     default: {
       warning("Unsupported platform: ${::operatingsystem}")
     }
  }

}
