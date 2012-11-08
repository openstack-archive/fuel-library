# This is an example of a very basic 3-node setup for puppetdb.

# This node is our puppet master.
node puppet {
    # Here we configure the puppet master to use puppetdb.
    class { 'puppetdb::master::config':
        puppetdb_server => 'puppetdb',
    }
}

# This node is our postgres server
node puppetdb-postgres {
    # Here we install and configure postgres and the puppetdb database instance
    class { 'puppetdb::database::postgresql':
        listen_addresses => 'puppetdb-postgres',
    }
}

# This node is our main puppetdb server
node puppetdb {
    # Here we install and configure the puppetdb server, and tell it where to
    # find the postgres database.
    class { 'puppetdb::server':
        database_host      => 'puppetdb-postgres',
    }
}
