class mcollective::client(
  $pskey = "secret",
  $user = "mcollective",
  $password = "mcollective",
  $host = "127.0.0.1",
  $stompport = "61613",
  $vhost = "mcollective",
  $stomp = false,
  ){

  case $::osfamily {
    'Debian': {
      # THIS PACKAGE ALSO INSTALLS REQUIREMENTS
      # mcollective-common
      # rubygems
      # rubygem-stomp
      $mcollective_client_package = "mcollective-client"
      $mcollective_client_config_template="mcollective/client.cfg.ubuntu.erb"
      $mcollective_agent_path = "/usr/share/mcollective/plugins/mcollective/agent"
#      $additional_packages = "ruby-dev"
    }
    'RedHat': {
      $mcollective_client_package = "mcollective-client"
      $mcollective_client_config_template="mcollective/client.cfg.erb"
      $mcollective_agent_path = "/usr/libexec/mcollective/mcollective/agent"
#      $additional_packages = "ruby-devel"
    }
    default: {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }

# install ruby-devel, make and gcc to exclude problems with installing astute gem
#  package { $additional_packages :
#    ensure => 'present',
#  }
#
#  package { "make" :
#    ensure => 'present',
#  }
#
#  package { "gcc" :
#    ensure => 'present',
#  }

  package { $mcollective_client_package :
    ensure => 'present',
  }

  exec {"patch_mcollective_no_ttl" :
    command => "find / -name message.rb | grep mcollective | xargs sed -i 's/msg_age = Time.now.utc.to_i - msgtime/msg_age = 0 #Time.now.utc.to_i - msgtime/g'",
    path => ['/bin','/sbin','/usr/bin','/usr/sbin'],
    provider => shell,
    require => Package[$mcollective_client_package],
  }

  file {"/etc/mcollective/client.cfg" :
    content => template($mcollective_client_config_template),
    owner => root,
    group => root,
    mode => 0600,
    require => Package[$mcollective_client_package],
  }
  
  file {"${mcollective_agent_path}/puppetd.ddl" :
    content => template("mcollective/puppetd.ddl.erb"),
    owner => root,
    group => root,
    mode => 0600,
    require => Package[$mcollective_client_package],
  }
  
  file {"${mcollective_agent_path}/puppetd.rb" :
    content => template("mcollective/puppetd.rb.erb"),
    owner => root,
    group => root,
    mode => 0600,
    require => Package[$mcollective_client_package],
  }
}
