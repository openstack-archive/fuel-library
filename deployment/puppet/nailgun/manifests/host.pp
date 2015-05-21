class nailgun::host(
$production,
$cobbler_host = '127.0.0.1',
$dns_search = 'domain.tld',
$dns_domain = 'domain.tld',
$nailgun_group = 'nailgun',
$nailgun_user = 'nailgun',
$gem_source = 'http://localhost/gems/',
$repo_root = '/var/www/nailgun',
$monitord_user = 'monitd',
$monitord_password = 'monitd',
$monitord_tenant = 'services',
$admin_iface = 'eth0',
) {
  #Enable cobbler's iptables rules even if Cobbler not called
  include cobbler::iptables
  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  firewall { '002 accept related established rules':
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  } ->
  class { 'nailgun::iptables':
    admin_iface => $admin_iface,
  }

  class { 'nailgun::auxiliaryrepos':
    repo_root  => $repo_root,
  }

  nailgun::sshkeygen { '/root/.ssh/id_rsa':
    homedir   => '/root',
    username  => 'root',
    groupname => 'root',
    keytype   => 'rsa',
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

  #Deprecated dhcrelay config, but keep package installed
  package {'dhcp':
    ensure => installed,
  }
  service {'dhcrelay':
    ensure => stopped,
  }

  # Since we're supporting multiple repos, it's a good idea to support
  # also priorities for them. Just in case.
  package {'yum-plugin-priorities':
    ensure => installed,
  }

  # Enable monit
  class { 'monit': }

  # Free disk space monitoring
  package { 'fuel-notify':
    ensure => latest,
    notify => Service['monit'],
  }

  file { '/etc/fuel/free_disk_check.yaml':
    content => template('nailgun/free_disk_check.yaml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

}
