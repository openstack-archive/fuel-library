class puppet::thin () {
  include puppet::service
  include puppet::master

  $thin_daemon_config_template = "puppet/init_puppetmaster_thin.erb"

  case $::osfamily {
    'RedHat' : {
      $thin_path ="/usr/bin/thin"
      package {
        "make":
          ensure => latest;
          
        "gcc":
          ensure => latest;
          
        "gcc-c++":
          ensure => latest;
        
        "rubygems":
          ensure => latest;


        rrdtool-devel:
          ensure => latest;

        "ruby-devel":
          ensure => latest;

         fcgi-devel:
          ensure => latest;
      } ->
      
      package {
        bacon:
          ensure   => present,
          provider => gem;

        rack:
          ensure   => present,
          provider => gem;

        rake:
          ensure   => present,
          provider => gem;

        memcache-client:
          ensure   => present,
          provider => gem;

        mongrel:
          ensure   => present,
          provider => gem;

        fcgi:
          ensure   => present,
          provider => gem,
          require  => Package[fcgi-devel];

        thin:
          ensure   => present,
          provider => gem,
          require  => [Package[bacon], Package[rack], Package[rake], Package[fcgi], Package[memcache-client], Package[mongrel]];
      }
    }
    'Debian' : {
      $thin_path ="/usr/local/bin/thin"
      package {
        "make":
          ensure => latest;
          
        "gcc":
          ensure => latest;
        
        "rubygems1.8":
          ensure => latest;

        librrd-ruby:
          ensure => latest;

        "ruby1.8-dev":
          ensure => latest;

        libfcgi-dev:
          ensure => latest;

        "libfcgi-ruby1.8":
          ensure => latest;
      } ->
      package {

        bacon:
          ensure   => present,
          provider => gem;

        rack:
          ensure   => present,
          provider => gem;

        rake:
          ensure   => present,
          provider => gem;

        memcache-client:
          ensure   => present,
          provider => gem;

        mongrel:
          ensure   => present,
          provider => gem;

        fcgi:
          ensure   => present,
          provider => gem,
          require  => Package[libfcgi-dev];

        thin:
          ensure   => present,
          provider => gem,
          require  => [Package[bacon], Package[rack], Package[rake], Package[fcgi], Package[memcache-client], Package[mongrel]];
      }
    }
    default  : {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian"
      )
    }
  } 
  
  file { "/etc/init.d/puppetmaster":
    content => template($thin_daemon_config_template),
    owner   => 'root',
    group   => 'root',
    mode    => 0755,
    notify  => Service["puppetmaster"],
    require => [Exec["puppetmaster_stopped"], Package[thin]],
  }

}