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

  package { $mcollective_client_package :
    ensure => 'present',
  }

  package { 'nailgun-mcagents': }

  file {"/etc/mcollective/client.cfg" :
    content => template($mcollective_client_config_template),
    owner => root,
    group => root,
    mode => 0600,
    require => Package[$mcollective_client_package],
  }
  ###DEPRECATED - RETAINED FROM OLD FUEL VERSIONS####
  #  file {"${mcollective_agent_path}/puppetd.ddl" :
  #  content => template("mcollective/puppetd.ddl.erb"),
  #  owner => root,
  #  group => root,
  #  mode => 0600,
  #  require => Package[$mcollective_client_package],
  # }
  #
  # file {"${mcollective_agent_path}/puppetd.rb" :
  #  content => template("mcollective/puppetd.rb.erb"),
  #  owner => root,
  #  group => root,
  #  mode => 0600,
  #  require => Package[$mcollective_client_package],
  # }
}
