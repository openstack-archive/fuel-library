class nailgun::mcollective(
  $mco_pskey = "unset",
  $mco_user = "mcollective",
  $mco_password = "marionette",
  $mco_vhost = "mcollective",
  $mco_host = "localhost",
  ){

  class { "mcollective::rabbitmq":
    user => $mco_user,
    password => $mco_password,
    stomp => false,
  }

  class { "mcollective::client":
    pskey => $mco_pskey,
    vhost => $mco_vhost,
    user => $mco_user,
    password => $mco_password,
    host => $mco_host,
    stomp => false,
  }
   class { "mcollective::server":
    pskey => $mco_pskey,
    vhost => $mco_vhost,
    user => $mco_user,
    password => $mco_password,
    host => $mco_host,
    stomp => false,
  }
 
}
