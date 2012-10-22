puppetlabs/puppetdb - PuppetDB Management
-----------------------------------------

Purpose:	    Install and manage the PuppetDB server and database, and
                configure the Puppet master to use PuppetDB
Module:	        puppetlabs/puppetdb (http://forge.puppetlabs.com/cprice404/puppetdb)
Puppet Version:	2.7+
Platforms:	    RHEL6, Debian6, Ubuntu 10.04

One of the new projects that we at Puppet Labs are excited about right now is
PuppetDB, our new “data warehouse” for managing storage and retrieval of all
platform-generated data.  (If you haven’t checked it out yet, have a look at
[Nick Lewis’ blog
post](http://puppetlabs.com/blog/introducing-puppetdb-put-your-data-to-work/) or
the [PuppetDB documentation](http://docs.puppetlabs.com/puppetdb/).)  Currently,
it offers a huge performance improvement for exported and collected resources,
as well as several other great features.  We’re even more excited about some of
the not-quite-released functionality that is in the pipeline, so stay tuned for
more information!

Installing and configuring PuppetDB isn’t *too* difficult, but we knew that it
could and should be even easier than it was.  That’s where the new
`puppetlabs/puppetdb` module comes in.  Whether you just want to throw PuppetDB
onto a test system as quickly as possible so that you can check it out, or you
want finer-grained access to managing the individual settings and configuration,
this module aims to let you dive in at exactly the level of involvement that you
desire.

Here are some of the capabilities of the new 1.0 release of the `puppetdb`
module; almost all of these are optional, so you are free to pick and choose
which ones suit your needs:

* Installs and manages the core PuppetDB server
* Installs and manages the underlying database server (PostgreSQL or a simple
embedded database)
* Configures your Puppet master to use PuppetDB
* Optional support for opening the PuppetDB port in your firewall on
RedHat-based distros
* Validates your database connection before applying PuppetDB configuration
changes, to help make sure that PuppetDB doesn’t end up in a broken state
* Validates your PuppetDB connection before applying configuration changes to
the Puppet master, to help make sure that your master doesn’t end up in a broken
state

Installing the module
---------------------

Installing the PuppetDB module is a breeze using the Puppet module tool
(available in Puppet 2.7.14+ and Puppet Enterprise 2.5+):

    $ puppet module install puppetlabs/puppetdb
    puppet module install puppetlabs/puppetdb
    Preparing to install into /etc/puppet/modules ...
    Downloading from http://forge.puppetlabs.com ...
    Installing -- do not interrupt ...
    /etc/puppet/modules
    └─┬ puppetlabs-puppetdb (v0.1.1)
      ├── cprice404-inifile (v0.0.2)
      ├─┬ inkling-postgresql (v0.3.0)
      │ └── puppetlabs-stdlib (v3.0.1)
      └── puppetlabs-firewall (v0.0.4)
    $

Resource Overview
-----------------

Let’s take a quick peek at the main classes and types defined by the module. 
(We’ll take a more in-depth look, with examples, in the following section.)

##### `puppetdb` class

This is a sort of ‘all-in-one’ class for the PuppetDB server.  It’ll get you up
and running with everything you need (including database setup and management)
on the server side.  The only other thing you’ll need to do is to configure your
Puppet master to use PuppetDB... which leads us to:

##### `puppetdb::master::config` class

This class should be used on your Puppet master node.  It’ll verify that it can
successfully communicate with your PuppetDB server, and then configure your
master to use PuppetDB.

***NOTE***: Using this class involves allowing the module to manipulate your
puppet configuration files; in particular: `puppet.conf` and `routes.yaml`.  The
`puppet.conf` changes are supplemental and should not affect any of your existing
settings, but the `routes.yaml` file will be overwritten entirely.  If you have an
existing `routes.yaml` file, you will want to take care to use the `manage_routes`
parameter of this class to prevent the module from managing that file, and
you’ll need to manage it yourself.

##### `puppetdb::server` class

This is for managing the PuppetDB server independently of the underlying
database that it depends on; so it’ll manage the PuppetDB package, service,
config files, etc., but will allow you to manage the database (e.g. postgresql)
however you see fit.

###### `puppetdb::database::postgresql` class

This is a class for managing a postgresql server for use by PuppetDB.  It can
manage the postgresql packages and service, as well as creating and managing the
puppetdb database and database user accounts.

##### Low-level classes

There are several lower-level classes in the module (e.g., `puppetdb::master::*`
and `puppetdb::server::*` which you can use to manage individual configuration
files or other parts of the system.  In the interest of brevity, we’ll skip over
those for now... but if you need more fine-grained control over your setup, feel
free to dive into the module and have a look!)

Example Usage
-------------

Enough with the gory details, let’s talk about how to actually use the thing!

When you are first getting started with PuppetDB, there are a few decision
you’ll have to make:

* Which database back-end should I use?  (The current choices are PostgreSQL or
our embedded database; we’ll discuss this more a bit later on.)
* Should I run the database on the same node that I run PuppetDB on?
* Should I run PuppetDB on the same node that I run my master on?

The answers to those questions will be largely dependent on your Puppet
environment.  How many nodes are you managing?  What kind of hardware are you
running on?  Is your current load approaching the limits of your hardware?

### The Simple Case

Since I won’t be able to answer all of those questions for you, we’ll start off
with the absolute simplest case: using our default database (PostgreSQL), and
running everything (PostgreSQL, PuppetDB, Puppet master) all on the same node. 
This setup will be great for testing / experimental environment, and may be
sufficient for many real-world deployments depending on the number of nodes
you’re managing.  So, what would our manifest look like in this case?

    node puppetmaster {
       # Configure puppetdb and its underlying database
       include puppetdb
       # Configure the puppet master to use puppetdb
       include puppetdb::master::config
    }


That’s it!  Obviously, you can provide some parameters for these classes if
you’d like more control, but that is literally all that it will take to get you
up and running with the default configuration.  Here are the steps that this
manifest will trigger:

* Install PostgreSQL on the node if it’s not already there
* Create the PuppetDB postgres database instance and user account
* Validate the postgres connection and, if successful, install and configure
PuppetDB
* Validate the PuppetDB connection and, if successful, modify the Puppet master
config files to use PuppetDB
* Restart the Puppet master so that it will pick up the config changes

If your logging level is set to INFO or finer, you should start seeing
PuppetDB-related log messages appear in both your Puppet master log and your
PuppetDB log as subsequent agent runs occur.

Note: If you’d prefer to use PuppetDB’s embedded database rather than
PostgreSQL, have a look at the database parameter on the puppetdb class.  The
embedded db can be useful for testing and very small production environments,
but is not recommended for production environments as it consumes a great deal
of memory as your number of nodes increases.

### A Distributed Setup

In many cases, you’ll prefer not to install PuppetDB on the same node as the
Puppet master.  Your environment will be easier to scale if you are able to
dedicate hardware to the individual system components.  You may even choose to
run the PuppetDB server on a different node from the PostgreSQL database that it
uses to store its data.  So let’s have a look at what a manifest for that
scenario might look like:

    # This is an example of a very basic 3-node setup for PuppetDB.

    # This node is our Puppet master.
    node puppet {
        # Here we configure the puppet master to use PuppetDB,
        # and tell it that the hostname is ‘puppetdb’
        class { 'puppetdb::master::config':
            puppetdb_server => 'puppetdb',
        }
    }

    # This node is our postgres server
    node puppetdb-postgres {
        # Here we install and configure postgres and the puppetdb
        # database instance, and tell postgres that it should
        # listen for connections to the hostname ‘puppetdb-postgres’
        class { 'puppetdb::database::postgresql':
            listen_addresses => 'puppetdb-postgres',
        }
    }

    # This node is our main puppetdb server
    node puppetdb {
        # Here we install and configure PuppetDB, and tell it where to
        # find the postgres database.
        class { 'puppetdb::server':
            database_host      => 'puppetdb-postgres',
        }
    }

That’s it!  This should be all it takes to get a 3-node, distributed
installation of PuppetDB up and running.  Note that if you prefer, you could
easily move two of these classes to a single node and end up with a 2-node setup
instead.

### Cross-node Dependencies

If you’re playing along at home, you may have spotted some cross-node
dependencies here and you’ve probably recognized that the order that these nodes
check in with the puppet master will have serious implications for getting
everything up and running.  It would be very bad to configure the master to use
the PuppetDB server before that server was up and running.  Likewise, it
wouldn’t be great to try to start up the PuppetDB server pointing to a Postgres
server that isn’t actually running Postgres yet.

The module handles this problem for you by taking a sort of “eventual
consistency” approach.  There’s nothing that the module can do to control the
order in which your nodes check in, but the module *can* check to verify that
the services it depends on are up and running before it makes configuration
changes--so that’s what it does.

When your Puppet master node checks in, it will validate the connectivity to the
PuppetDB server before it applies its changes to the Puppet master config files.
 If it can’t connect to PuppetDB, then the puppet run will fail and the previous
config files will be left intact.  This prevents your master from getting into a
broken state where all incoming Puppet runs fail because the master is
configured to use a PuppetDB server that doesn’t exist yet.  The same strategy
is used to handle the dependency between the PuppetDB server and the postgres
server.

What does this all mean to you, as a user?  Well, it basically means that the
first time you add this stuff to your manifests, you may see a few failed Puppet
runs on the affected nodes.  This should be limited to 1 failed run on the
PuppetDB node, and up to 2 failed runs on the Puppet master node.  After that,
all of the dependencies should be satisfied and your puppet runs should start to
succeed again.

If you prefer, you can manually trigger puppet runs on the nodes in the correct
order (Postgres, PuppetDB, Puppet master) and you should avoid any failed runs.

Configuring the module
----------------------

The module supports a large number of configuration options.  If you’d like more
control over things like:

* whether or not to open the PuppetDB port on the firewall
* what address the PuppetDB server should listen on
* what version of PuppetDB to use
* what address the PostgreSQL server should listen on
* PostgreSQL database name, username, password, etc.
* custom paths to various configuration files

and more, please take a peek at the individual classes.  They expose a large
number of parameters and should hopefully be documented fairly well.  (We won’t
cover them here since this post has already gotten a bit long-winded, if I do
say so myself, but perhaps we’ll do a follow-up blog post in the future that
goes into greater detail.)

Conclusion
----------

That’s about it for now.  We hope that this module makes it So Darn Easy to get
up and running with PuppetDB that you simply can’t come up with any more excuses
not to go ahead and do it right now!  We think you’ll be happy you did--not only
because of its current power and features, but also because of all of the great
things we have in store for it in the near future.

If  you have any questions, suggestions, or feedback, please send them to Ryan
or Chris!  If there’s a setting that you’d like to be able to manage that we
haven’t exposed yet, let us know, or better yet, file a pull request to the
module project: https://github.com/puppetlabs/puppetlabs-puppetdb
