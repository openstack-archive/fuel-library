# Class: puppetdb::params
#
#   The puppetdb configuration settings.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class puppetdb::params {
  # TODO: need to condition this based on whether we are a PE install or not

  $ssl_listen_address    = $::clientcert
  $ssl_listen_port       = '8081'
  $listen_port           = '8080'

  $database          = 'postgres'

  # The remaining database settings are not used for an embedded database
  $database_host          = 'localhost'
  $database_port          = '5432'
  $database_name          = 'puppetdb'
  $database_username      = 'puppetdb'
  $database_password      = 'puppetdb'

  $puppetdb_version       = 'present'

  $gc_interval            = '60'
  $confdir                = '/etc/puppetdb/conf.d'

#  # TODO: need to condition this for PE
  $puppet_service_name  = 'puppetmaster'
}
