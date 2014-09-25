# == Class: n1kv_vem
#
# Deploy N1KV VEM on compute and network nodes.
# Support exists and tested for RedHat.
# (For Ubuntu/Debian platforms few changes and testing pending.)
#
# === Parameters
# [*n1kv_vsm_ip*]
#   (required) N1KV VSM(Virtual Supervisor Module) VM's IP.
#   Defaults to 127.0.0.1
#
# [*n1kv_vsm_domainid*]
#   (required) N1KV VSM DomainID.
#   Defaults to 1000
#
# [*host_mgmt_intf*]
#   (required) Management Interface of node where VEM will be installed.
#   Defaults to eth1
#
# [*uplink_profile*]
#   (optional) Uplink Interfaces that will be managed by VEM. The uplink
#      port-profile that configures these interfaces should also be specified.
#   (format)
#    $uplink_profile = { 'eth1' => 'profile1',
#                        'eth2' => 'profile2'
#                       },
#   Defaults to empty
#
# [*vtep_config*]
#   (optional) Virtual tunnel interface configuration.
#              Eg:VxLAN tunnel end-points.
#   (format)
#   $vtep_config = { 'vtep1' => { 'profile' => 'virtprof1',
#                                 'ipmode'  => 'dhcp'
#                               },
#                    'vtep2' => { 'profile'   => 'virtprof2',
#                                 'ipmode'    => 'static',
#                                 'ipaddress' => '192.168.1.1',
#                                 'netmask'   => '255.255.255.0'
#                               }
#                  },
#   Defaults to empty
#
# [*node_type*]
#   (optional). Specify the type of node: 'compute' (or) 'network'.
#   Defaults to 'compute'
#
# All the above parameter values will be used in the config file: n1kv.conf
#
# [*vteps_in_same_subnet*]
#   (optional)
#   The VXLAN tunnel interfaces created on VEM can belong to same IP-subnet.
#   In such case, set this parameter to true. This results in below
#   'sysctl:ipv4' values to be modified.
#     rp_filter (reverse path filtering) set to 2(Loose).Default is 1(Strict)
#     arp_ignore (arp reply mode) set to 1:reply only if target ip matches
#                                that of incoming interface. Default is 0
#     arp_announce (arp announce mode) set to 1. Default is 0
#   Please refer Linux Documentation for detailed description
#   http://lxr.free-electrons.com/source/Documentation/networking/ip-sysctl.txt
#
#   If the tunnel interfaces are not in same subnet set this parameter to false.
#   Note that setting to false causes no change in the sysctl settings and does
#   not revert the changes made if it was originally set to true on a previous
#   catalog run.
#
#   Defaults to false
#
# [*n1kv_source*]
#   (optional)
#     n1kv_source ==> VEM package location. One of below
#       A)URL of yum repository that hosts VEM package.
#       B)VEM RPM/DPKG file name, If present locally in 'files' folder
#       C)If not specified, assumes that VEM image is available in
#         default enabled repositories.
#   Defaults to empty
#
# [*n1kv_version*]
#   (optional). Specify VEM package version to be installed.
#       Not applicable if 'n1kv_source' is a file. (Option-B above)
#   Defaults to 'present'
#
# [*package_ensure*]
#   (optional) Ensure state for dependent packages: Openvswitch/libnl.
#   Defaults to 'present'.
#
# [*enable*]
#   (optional) Enable state for service. Defaults to 'true'.
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
class neutron::agents::n1kv_vem (
  $n1kv_vsm_ip          = '127.0.0.1',
  $n1kv_vsm_domain_id   = 1000,
  $host_mgmt_intf       = 'eth1',
  $uplink_profile       = {},
  $vtep_config          = {},
  $node_type            = 'compute',
  $vteps_in_same_subnet = false,
  $n1kv_source          = '',
  $n1kv_version         = 'present',
  $package_ensure       = 'present',
  $enable               = true,
  $manage_service       = true
) {

  include neutron::params

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

  if($::osfamily != 'Redhat') {
    #current support exists for Redhat family.
    #Support for Debian will be added soon.
    fail("Unsupported osfamily ${::osfamily}")
  }

  #Check source of n1kv-vem image:yum-repo (or) local file in 'files' directory
  if $n1kv_source != '' {
    if ($n1kv_source =~ /^http/) or ($n1kv_source =~ /^ftp/) {
      $vemimage_uri = 'repo'
    } else {
      $vemimage_uri = 'file'
      $vemtgtimg    = "/var/n1kv/${n1kv_source}"
    }
  } else {
    $vemimage_uri = 'unspec'
  }


  package { 'libnl':
    ensure => $package_ensure,
    name   => $::neutron::params::libnl_package
  }

  package { 'openvswitch':
    ensure => $package_ensure,
    name   => $::neutron::params::ovs_package
  }

  file {
    '/etc/n1kv':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    '/var/n1kv':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
  }

  #specify template corresponding to 'n1kv.conf'
  file {'/etc/n1kv/n1kv.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0664',
    content => template('neutron/n1kv.conf.erb'),
    require => File['/etc/n1kv'],
  }

  if $vemimage_uri == 'file' {
    #specify location on target-host where image file will be downloaded to.
    #Later vem package: 'nexus1000v' will be installed from this file.
    file { $vemtgtimg:
      owner   => 'root',
      group   => 'root',
      mode    => '0664',
      source  => "puppet:///modules/neutron/${n1kv_source}",
      require => File['/var/n1kv'],
    }
    package {'nexus1000v':
      ensure   => $n1kv_version,
      provider => $::neutron::params::package_provider,
      source   => $vemtgtimg,
      require  => File[$vemtgtimg]
    }
  } else {
    if $vemimage_uri == 'repo' {
      #vem package: 'nexus1000v' will be downloaded and installed
      #from below repo.
      yumrepo { 'cisco-vem-repo':
        baseurl  => $n1kv_source,
        descr    => 'Repo for VEM Image',
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => "${n1kv_source}/RPM-GPG-KEY"
        #proxy   => '_none_',
      }
    }
    package {'nexus1000v':
      ensure => $package_ensure
    }
  }

  if $manage_service {
    if $enable {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  service { 'nexus1000v':
    ensure    => $service_ensure,
  }

  #Upon config change in 'n1kv.conf' execute below 'vemcmd reread config'.
  #No need to restart service.
  exec { 'vemcmd reread config':
    subscribe   => File['/etc/n1kv/n1kv.conf'],
    refreshonly => true,
    require     => Service['nexus1000v']
  }

  if $vteps_in_same_subnet == true {
    $my_sysctl_settings = {
      'net.ipv4.conf.default.rp_filter'    => { value => 2 },
      'net.ipv4.conf.all.rp_filter'        => { value => 2 },
      'net.ipv4.conf.default.arp_ignore'   => { value => 1 },
      'net.ipv4.conf.all.arp_ignore'       => { value => 1 },
      'net.ipv4.conf.all.arp_announce'     => { value => 2 },
      'net.ipv4.conf.default.arp_announce' => { value => 2 },
    }
    create_resources(sysctl::value,$my_sysctl_settings)
  }

  Package['libnl']            -> Package['nexus1000v']
  Package['openvswitch']      -> Package['nexus1000v']
  File['/etc/n1kv/n1kv.conf'] -> Package['nexus1000v']
  Package['nexus1000v']       ~> Service['nexus1000v']
}
