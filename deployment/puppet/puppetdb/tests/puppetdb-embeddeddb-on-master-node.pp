# This is an example of how to get puppetdb up and running on the same node
# where your puppet master is running, using the embedded database (which is
# mostly just for testing or very small-scale deployments).

# Configure puppetdb.
class { 'puppetdb':
    database => 'embedded',
}

# Configure the puppet master to use puppetdb.
include puppetdb::master::config
