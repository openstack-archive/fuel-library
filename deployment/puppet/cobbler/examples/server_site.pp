$server              = '10.0.0.100'
$domain_name         = 'mirantis.com'
$name_server         = '10.0.0.100'
$next_server         = '10.0.0.100'
$dhcp_start_address  = '10.0.0.201'
$dhcp_end_address    = '10.0.0.254'
$dhcp_netmask        = '255.255.255.0'
$dhcp_gateway        = '10.0.0.100'
$cobbler_user        = 'cobbler'
$cobbler_password    = 'cobbler'
$pxetimeout          = '0'

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
      key_source => 'https://fedoraproject.org/static/0608B895.txt',
      stage      => 'openstack-custom-repo',
    }
  }
  default: {
    fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
  }
}

node fuel-01 {
  class { cobbler::server:
    server              => $server,

    domain_name         => $domain_name,
    name_server         => $name_server,
    next_server         => $next_server,

    dhcp_start_address  => $dhcp_start_address,
    dhcp_end_address    => $dhcp_end_address,
    dhcp_netmask        => $dhcp_netmask,
    dhcp_gateway        => $dhcp_gateway,

    cobbler_user        => $cobbler_user,
    cobbler_password    => $cobbler_password ,

    pxetimeout          => $pxetimeout,
  }
}
