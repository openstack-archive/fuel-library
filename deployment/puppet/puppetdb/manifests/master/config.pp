# Class: puppetdb::master::config
#
# This class configures the puppet master to use puppetdb.  This includes installing
# all of the required master-specific puppetdb packages and managing or deploying
# the necessary config files (`puppet.conf`, `routes.yaml`, and `puppetdb.conf`).
#
# ***WARNING***: the default behavior of this module is to overwrite puppet's
#  `routes.yaml` file, to configure it to use puppetdb.  If you have any custom
#  settings in your `routes.yaml` file, you'll want to pass `false` for
#  the `manage_routes` parameter and you'll have to manage that file yourself.
#
# Parameters:
#   ['puppetdb_server'] - The dns name or ip of the puppetdb server
#                          (defaults to the certname of the current node)
#   ['puppetdb_port']   - The port that the puppetdb server is running on (defaults to 8081)
#   ['manage_routes']   - If true, the module will overwrite the puppet master's routes
#                         file to configure it to use puppetdb (defaults to true)
#   ['manage_storeconfigs'] - If true, the module will manage the puppet master's
#                         storeconfig settings (defaults to true)
#   ['puppet_confdir']  - Puppet's config directory; defaults to /etc/puppet
#   ['puppet_conf']     - Puppet's config file; defaults to /etc/puppet/puppet.conf
#   ['puppetdb_version']   - The version of the `puppetdb` package that should
#                         be installed.  You may specify an explicit version
#                         number, 'present', or 'latest'.  Defaults to
#                         'present'.
#   ['restart_puppet']  - If true, the module will restart the puppet master when
#                         necessary.  The default is 'true'.  If set to 'false',
#                         you must restart the service manually in order to pick
#                         up changes to the config files (other than `puppet.conf`).
#
# Actions:
# - Configures the puppet master to use puppetdb.
#
# Requires:
# - Inifile
#
# Sample Usage:
#   class { 'puppetdb::master::config':
#       puppetdb_server          => 'my.host.name',
#       puppetdb_port            => 8081,
#   }
#
# TODO: port this to use params
#
class puppetdb::master::config(
  $puppetdb_server      = $::clientcert,
  $puppetdb_port        = 8081,
  $manage_routes        = true,
  $manage_storeconfigs  = true,
  $puppet_confdir       = '/etc/puppet',
  $puppet_conf          = '/etc/puppet/puppet.conf',
  $puppetdb_version     = $puppetdb::params::puppetdb_version,
  $restart_puppet       = true,
  $puppet_service_name  = $puppetdb::params::puppet_service_name,
) inherits puppetdb::params {

  package { 'puppetdb-terminus':
    ensure  => $puppetdb_version,
  }

  # Validate the puppetdb connection.  If we can't connect to puppetdb then we
  # *must* not perform the other configuration steps, or else
  puppetdb_conn_validator { 'puppetdb_conn':
    puppetdb_server => $puppetdb_server,
    puppetdb_port   => $puppetdb_port,
    require         => Package['puppetdb-terminus'],
  }

  # This is a bit of puppet chicanery that allows us to create a
  # conditional dependency.  Basically, we're saying that "if the PuppetDB
  # service is being managed in this same catalog, it needs to come before
  # this validator."
  Service<|title == 'puppetdb'|> -> Puppetdb_conn_validator['puppetdb_conn']

  # Conditionally manage the `routes.yaml` file.  Restart the puppet service
  # if changes are made.
  if ($manage_routes) {
    class { 'puppetdb::master::routes':
      puppet_confdir => $puppet_confdir,
      require        => Puppetdb_conn_validator['puppetdb_conn'],
    }
  }

  # Conditionally manage the storeconfigs settings in `puppet.conf`.  We don't
  # need to trigger a restart of the puppet master service for this one, because
  # it polls it automatically.
  if ($manage_storeconfigs) {
    class { 'puppetdb::master::storeconfigs':
      puppet_conf => $puppet_conf,
      require     => Puppetdb_conn_validator['puppetdb_conn'],
    }
  }

  # Manage the `puppetdb.conf` file.  Restart the puppet service if changes
  # are made.
  class { 'puppetdb::master::puppetdb_conf':
    server         => $puppetdb_server,
    port           => $puppetdb_port,
    puppet_confdir => $puppet_confdir,
    require        => Puppetdb_conn_validator['puppetdb_conn'],
  }

  if ($restart_puppet) {
    # We will need to restart the puppet master service if certain config
    # files are changed, so here we make sure it's in the catalog.
    if ! defined(Service[$puppet_service_name]) {
      service { $puppet_service_name:
        ensure => running,
      }
    }

    Class['puppetdb::master::puppetdb_conf'] ~> Service[$puppet_service_name]
    Class['puppetdb::master::routes']        ~> Service[$puppet_service_name]
  }

}
