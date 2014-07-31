class nailgun::host(
$production,
$cobbler_host = '127.0.0.1',
$dns_search = "domain.tld",
$dns_domain = "domain.tld",
$nailgun_group = "nailgun",
$nailgun_user = "nailgun",
$gem_source = "http://localhost/gems/",
)
{
  #Enable cobbler's iptables rules even if Cobbler not called
  include cobbler::iptables
  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  firewall { '002 accept related established rules':
    proto   => 'all',
    state   => ['RELATED', 'ESTABLISHED'],
    action  => 'accept',
  } ->
  class { "nailgun::iptables": }

  nailgun::sshkeygen { "/root/.ssh/id_rsa":
    homedir => "/root",
    username => "root",
    groupname => "root",
    keytype => "rsa",
  }

  file { "/etc/ssh/sshd_config":
    content => template("nailgun/sshd_config.erb"),
    owner => 'root',
    group => 'root',
    mode  => '0600',
  }

  file { "/root/.ssh/config":
    content => template("nailgun/root_ssh_config.erb"),
    owner => 'root',
    group => 'root',
    mode  => '0600',
  }
  file { "/var/log/remote":
    ensure => directory,
    owner => 'root', 
    group => 'root',
    mode  => '0750',
  }
  file { "/var/www/nailgun/dump":
    ensure => directory,
    owner => 'root', 
    group => 'root',
    mode  => '0755',
  }

  file { "/etc/dhcp/dhcp-enter-hooks": 
    content => template("nailgun/dhcp-enter-hooks.erb"), 
    owner   => 'root', 
    group   => 'root', 
    mode    => '0755', 
  }

  file { "/etc/resolv.conf": 
    content => template("nailgun/resolv.conf.erb"), 
    owner   => 'root', 
    group   => 'root', 
    mode    => '0644', 
  }

  file { '/etc/dhcp/dhclient.conf':
    content => template("nailgun/dhclient.conf.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  #Suppress kernel messages to console
  sysctl::value{'kernel.printk': value=>'4 1 1 7'}

}
