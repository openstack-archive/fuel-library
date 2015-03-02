notice('MODULAR: api-proxy.pp')

class { '::apache':
  mpm_module    => false,
  default_vhost => false,
  purge_configs => false,
  servername    => $::hostname,
}

# We need to declare Horizon port and NameVirtualHost,
# otherwise class '::apache' will wipe them out from ports.conf
apache::listen { '80': }
apache::namevirtualhost { '*:80': }

# API proxy vhost
class {'osnailyfacter::apache_api_proxy':
  master_ip => hiera('master_ip'),
}
