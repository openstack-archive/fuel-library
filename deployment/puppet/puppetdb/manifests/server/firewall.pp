class puppetdb::server::firewall(
    $port                   = $puppetdb::params::ssl_listen_port,
    $manage_redhat_firewall = $puppetdb::params::manage_redhat_firewall,
) inherits puppetdb::params {
  # TODO: figure out a way to make this not platform-specific; debian and ubuntu
  # have an out-of-the-box firewall configuration that seems trickier to manage.
  # TODO: the firewall module should be able to handle this itself
  if ($manage_redhat_firewall and $puppetdb::params::firewall_supported) {

    exec { 'puppetdb-persist-firewall':
      command     => $puppetdb::params::persist_firewall_command,
      refreshonly => true,
    }

    Firewall {
      notify => Exec['puppetdb-persist-firewall']
    }

    firewall { "${port} accept - puppetdb":
      port   => $port,
      proto  => 'tcp',
      action => 'accept',
    }
  }
}
