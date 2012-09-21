
Exec { logoutput => true, path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'] }

stage {'openstack-custom-repo': before => Stage['main']}

case $::osfamily {
  'Debian': {
    class { 'apt':
      stage => 'openstack-ci-repo'
    }->
    class { 'openstack::repo::apt':
      key => '420851BC',
      location => 'http://172.18.66.213/deb',
      key_source => 'http://172.18.66.213/gpg.pub',
      origin => '172.18.66.213',
      stage => 'openstack-ci-repo'
    }
  }
  'RedHat': {
    class { 'openstack::repo::yum':
      repo_name  => 'openstack-epel-fuel',
      location   => 'http://download.mirantis.com/epel-fuel',
      key_source => 'https://fedoraproject.org/static/DE7F38BD.txt',
      stage      => 'openstack-custom-repo',
    }
  }
  default: {
    fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
  }
}

# package version mapping
$openstack_version = {
  'keystone'   => 'latest',
  'glance'     => 'latest',
  'horizon'    => 'latest',
  'nova'       => 'latest',
  'novncproxy' => 'latest',
}

$virtual_ip = '10.0.0.110'
$master_hostname = 'fuel-01'
$controller_public_addresses = ['10.0.0.101', '10.0.0.102']
$controller_internal_addresses = ['10.0.0.101', '10.0.0.102']
$floating_range = '10.0.1.0/28'
$fixed_range = '10.0.2.0/28'
$controller_hostnames = ['fuel-01', 'fuel-02']
$public_interface = 'eth1'
$internal_interface = 'eth1'
$internal_address = $ipaddress_eth1
$private_interface = 'eth2'
$multi_host = true
$network_manager = 'nova.network.manager.FlatDHCPManager'
$verbose = true
$auto_assign_floating_ip = false
$mysql_root_password     = 'nova'
$admin_email             = 'openstack@openstack.org'
$admin_password          = 'nova'
$keystone_db_password    = 'nova'
$keystone_admin_token    = 'nova'
$glance_db_password      = 'nova'
$glance_user_password    = 'nova'
$nova_db_password        = 'nova'
$nova_user_password      = 'nova'
$rabbit_password         = 'nova'
$rabbit_user             = 'nova'

node /fuel-0[12]/ {
    class { 'openstack::controller_ha': 
      controller_public_addresses => $controller_public_addresses,
      public_interface        => $public_interface,
      internal_interface      => $internal_interface,
      private_interface       => $private_interface,
      virtual_ip              => $virtual_ip,
      controller_internal_addresses => $controller_internal_addresses,
      master_hostname         => $master_hostname,
      floating_range          => $floating_range,
      fixed_range             => $fixed_range,
      multi_host              => $multi_host,
      network_manager         => $network_manager,
      verbose                 => $verbose,
      auto_assign_floating_ip => $auto_assign_floating_ip,
      mysql_root_password     => $mysql_root_password,
      admin_email             => $admin_email,
      admin_password          => $admin_password,
      keystone_db_password    => $keystone_db_password,
      keystone_admin_token    => $keystone_admin_token,
      glance_db_password      => $glance_db_password,
      glance_user_password    => $glance_user_password,
      nova_db_password        => $nova_db_password,
      nova_user_password      => $nova_user_password,
      rabbit_password         => $rabbit_password,
      rabbit_user             => $rabbit_user,
      rabbit_nodes            => $controller_hostnames,
      memcached_servers       => $controller_hostnames,
      export_resources        => false,
    }
}

node /fuel-[34]/ {
    class { 'openstack::compute':
      public_interface   => $public_interface,
      private_interface  => $private_interface,
      internal_address   => $internal_address,
      libvirt_type       => 'qemu',
      fixed_range        => $fixed_range,
      network_manager    => $network_manager,
      multi_host         => $multi_host,
      sql_connection     => "mysql://nova:${nova_db_password}@${virtual_ip}/nova",
      rabbit_nodes       => $controller_hostnames,
      rabbit_password    => $rabbit_password,
      rabbit_user        => $rabbit_user,
      glance_api_servers => "${virtual_ip}:9292",
      vncproxy_host      => $virtual_ip,
      verbose            => $verbose,
      vnc_enabled        => true,
      manage_volumes     => false,
      nova_user_password	=> $nova_user_password,
      cache_server_ip         => $controller_hostnames,
      service_endpoint	=> $virtual_ip,
    }
}

