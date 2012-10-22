# This is an example of how to get puppetdb up and running on the same node
# where your puppet master is running, using our recommended database server
# (postgresql).

# Configure puppetdb and its postgres database:
include puppetdb

# Configure the puppet master to use puppetdb.
include puppetdb::master::config
