class mcollective::client(
  $pskey = "secret",
  $stompuser = "mcollective",
  $stomppassword = "mcollective",
  $stomphost = "127.0.0.1",
  $stompport = "61613",
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
    }
    'RedHat': {
      $mcollective_client_package = "mcollective-client"
      $mcollective_client_config_template="mcollective/client.cfg.erb"
      $mcollective_agent_path = "/usr/libexec/mcollective/mcollective/agent"
    }
    default: {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }

  package { 'stomp':
    ensure   => 'installed',
    provider => 'gem',
  }
  
  package { $mcollective_client_package : }

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
