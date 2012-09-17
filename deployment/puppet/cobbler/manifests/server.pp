#
# This class is intended to serve as
# a way of deploying cobbler server.
#
# TODO - I need to make the choise of networking configurable
#
# [next_server] IP address that will be used as PXE tftp server. Required.
#
# [server] IP address that will be used as address of cobbler server.
# It is needed to download kickstart files, call cobbler API and
# so on. Required.
#
# [domain] Domain name that will be used as default for
# installed nodes. Required.
#
# [dhcp_range] Range of addresses to give via dhcp
#
# [gateway] Gateway address for installed nodes
#
# [cobbler_user] Cobbler web interface username
#
# [cobbler_password] Cobbler web interface password 
#
# [pxetimeout] Pxelinux will wail this count of 1/10 seconds before
# use default pxe item. To disable it use 0. Required.

class cobbler::server(
  # settings template
  $next_server = '127.0.0.1',
  $server = '127.0.0.1',

  # dnsmasq.template template
  $domain = 'example.com',
  $dhcp_range = '10.0.0.100,10.0.0.200',
  $gateway = '10.0.0.1',

  # users.digest template
  $cobbler_user = 'cobbler',
  $cobbler_password = 'cobbler',

  # pxedefault.template template
  $pxetimeout = '0'
  ) {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  case $operatingsystem {
    /(?i)(centos|redhat)/:  {
      $cobbler_package = "cobbler"
      $cobbler_web_package = "cobbler-web"
      $dnsmasq_package = "dnsmasq"
      $cobbler_service = "cobblerd"
      $cobbler_web_service = "httpd"
      $cobbler_additional_packages = ["syslinux"]
    }
    /(?i)(debian|ubuntu)/:  {
      $cobbler_package = "cobbler"
      $cobbler_web_package = "cobbler-web"
      $dnsmasq_package = "dnsmasq"
      $cobbler_service = "cobbler"
      $cobbler_web_service = "apache2"
      $cobbler_additional_packages = []
    }
  }

  package { $cobbler_package:
    ensure => installed
  }

  package { $cobbler_web_package:
    ensure => installed
  }

  package { $dnsmasq_package:
    ensure => installed
  }

  package { $cobbler_additional_packages: }
  
  define access_to_cobbler_port() {
    $port = $name
    $rule = "-p tcp -m state --state NEW -m tcp --dport $port -j ACCEPT"
    exec { "access_to_cobbler_port: $name": 
      command => "iptables -t filter -I INPUT 1 $rule; \
      /etc/init.d/iptables save",
      unless => "iptables -t filter -S INPUT | grep -q \"^-A INPUT $rule\""
    }
  }
  
  # OPERATING SYSTEM SPECIFIC ACTIONS
  case $operatingsystem {
    /(?i)(centos|redhat)/:{

      # HERE IS AN UGLY WORKAROUND TO MAKE COBBLER ABLE TO START
      # THERE IS AN ALTERNATIVE WAY TO ACHIEVE MAKE COBBLER STARTED
      # yum install policycoreutils-python
      # grep cobblerd /var/log/audit/audit.log | audit2allow -M cobblerpolicy
      # semodule -i cobblerpolicy.pp
      
      exec { "cobbler_disable_selinux":
        command => "setenforce 0",
        onlyif => "getenforce | grep -q Enforcing"
      }

      exec { "cobbler_disable_selinux_permanent":
        command => "sed -ie \"s/^SELINUX=enforcing/SELINUX=disabled/g\" /etc/selinux/config",
        onlyif => "grep -q \"^SELINUX=enforcing\" /etc/selinux/config"
      }
      

      # HERE IS IPTABLES RULES TO MAKE COBBLER AVAILABLE FROM OUTSIDE
      # https://github.com/cobbler/cobbler/wiki/Using%20Cobbler%20Import
      access_to_cobbler_port { "69": }
      access_to_cobbler_port { "80": }
      access_to_cobbler_port { "443": }
      access_to_cobbler_port { "25151": }
    }
  }

  service { $cobbler_service:
    enable => true,
    ensure => running,
    hasrestart => true,
    require => Package[$cobbler_package],
  }
  
  service { $cobbler_web_service:
    enable => true,
    ensure => running,
    hasrestart => true,
    require => Package[$cobbler_web_package],
  }

  exec {"cobbler_sync":
    command => "cobbler sync",
    refreshonly => true,
    returns => [0, 155],
    require => [Package[$cobbler_package],
                Package[$cobbler_additional_packages]],
  }
  
  file { "/etc/cobbler/modules.conf":
    content => template("cobbler/modules.conf.erb"),
    owner => root,
    group => root,
    mode => 0644,
    require => [Package[$cobbler_package]],
    notify => Service[$cobbler_service],
  }

  file {"/etc/cobbler/settings":
    content => template("cobbler/settings.erb"),
    owner => root,
    group => root,
    mode => 0644,
    require => [Package[$cobbler_package]],
    notify => [Exec["cobbler_sync"], Service[$cobbler_service]],
  }

  file {"/etc/cobbler/dnsmasq.template":
    content => template("cobbler/dnsmasq.template.erb"),
    owner => root,
    group => root,
    mode => 0644,
    require => [Package[$cobbler_package]],
    notify => [Exec["cobbler_sync"], Service[$cobbler_service]],
    
  }

  cobbler_digest_user {"cobbler":
    password => $cobbler_password,
    require => [Package[$cobbler_package]],
    notify => Service[$cobbler_service],
  }
  
  file {"/etc/cobbler/pxe/pxedefault.template":
    content => template("cobbler/pxedefault.template.erb"),
    owner => root,
    group => root,
    mode => 0644,
    require => [Package[$cobbler_package]],
    notify => [Exec["cobbler_sync"], Service[$cobbler_service]],
  }

  
  }                               
