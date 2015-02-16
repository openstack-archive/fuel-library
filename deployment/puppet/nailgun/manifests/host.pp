class nailgun::host(
$production,
$cobbler_host = '127.0.0.1',
$dns_search = 'domain.tld',
$dns_domain = 'domain.tld',
$nailgun_group = 'nailgun',
$nailgun_user = 'nailgun',
$confdir = "/etc/fuel/${::fuel_version['VERSION']['release']}/containers/",
$database_name,
$database_engine,
$database_host,
$database_port,
$database_user,
$database_passwd,

$staticdir,
$templatedir,

$rabbitmq_host,
$rabbitmq_astute_user,
$rabbitmq_astute_password,

$admin_network,
$admin_network_cidr,
$admin_network_size,
$admin_network_first,
$admin_network_last,
$admin_network_netmask,
$admin_network_mac,
$admin_network_ip,

$cobbler_host,
$cobbler_url,
$cobbler_user = "cobbler",
$cobbler_password = "cobbler",

$mco_pskey,
$mco_vhost,
$mco_host,
$mco_user,
$mco_password,
$mco_connector,

$puppet_master_hostname,

$exclude_network = $admin_network,
$exclude_cidr = $admin_network_cidr,

$keystone_host = '127.0.0.1',
$keystone_nailgun_user = 'nailgun',
$keystone_nailgun_pass = 'nailgun',

$dns_domain,

) {
  #Enable cobbler's iptables rules even if Cobbler not called
  include cobbler::iptables
  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  firewall { '002 accept related established rules':
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  } ->
  class { 'nailgun::iptables': }

  class { 'nailgun::host::nailgun':
    confdir         => "${confdir}/nailgun/",
    dns_domain      => $dns_domain,
    database_name   => $database_name,
    database_engine => $database_engine,
    database_host   => $database_host,
    database_port   => $database_port,
    database_user   => $database_user,
    database_passwd => $database_passwd,

    staticdir                => $staticdir,
    templatedir              => $templatedir,
    rabbitmq_host            => $rabbitmq_host,
    rabbitmq_astute_user     => $rabbitmq_astute_user,
    rabbitmq_astute_password => $rabbitmq_astute_password,

    admin_network         => $admin_network,
    admin_network_cidr    => $admin_network_cidr,
    admin_network_size    => $admin_network_size,
    admin_network_first   => $admin_network_first,
    admin_network_last    => $admin_network_last,
    admin_network_netmask => $admin_network_netmask,
    admin_network_mac     => $admin_network_mac,
    admin_network_ip      => $admin_network_ip,

    cobbler_host     => $cobbler_host,
    cobbler_url      => $cobbler_url,
    cobbler_user     => $cobbler_user,
    cobbler_password => $cobbler_password,

    mco_pskey     => $mco_pskey,
    mco_vhost     => $mco_vhost,
    mco_host      => $mco_host,
    mco_user      => $mco_user,
    mco_password  => $mco_password,
    mco_connector => $mco_connector,

    puppet_master_hostname => $puppet_master_hostname,
  }

  file { ["/etc/nailgun","/etc/nailgun/${::fuel_version['VERSION']['release']}/", "/etc/nailgun/${::fuel_version['VERSION']['release']}/containers/"]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '755',
  }
  file { '/etc/ssh/sshd_config':
    content => template('nailgun/sshd_config.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }

  file { '/root/.ssh/config':
    content => template('nailgun/root_ssh_config.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }

  file { '/var/log/remote':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }
  file { '/var/www/nailgun/dump':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/dhcp/dhcp-enter-hooks':
    content => template('nailgun/dhcp-enter-hooks.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/etc/resolv.conf':
    content => template('nailgun/resolv.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  file { '/etc/dhcp/dhclient.conf':
    content => template('nailgun/dhclient.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  #Suppress kernel messages to console
  sysctl::value{'kernel.printk': value => '4 1 1 7'}

  #Increase values for neighbour table
  sysctl::value{'net.ipv4.neigh.default.gc_thresh1': value => '256'}
  sysctl::value{'net.ipv4.neigh.default.gc_thresh2': value => '1024'}
  sysctl::value{'net.ipv4.neigh.default.gc_thresh3': value => '2048'}

}
