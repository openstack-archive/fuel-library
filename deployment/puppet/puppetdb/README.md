puppetlabs-puppetdb
===================

Purpose:	    Install and manage the PuppetDB server and database, and
                configure the Puppet master to use PuppetDB
Module:	        puppetlabs/puppetdb (http://forge.puppetlabs.com/puppetlabs/puppetdb)
Puppet Version:	2.7+
Platforms:	    RHEL6, Debian6, Ubuntu 10.04

Installing and configuring PuppetDB isn’t *too* difficult, but we knew that it
could and should be even easier than it was.  That’s where the new
`puppetlabs/puppetdb` module comes in.  Whether you just want to throw PuppetDB
onto a test system as quickly as possible so that you can check it out, or you
want finer-grained access to managing the individual settings and configuration,
this module aims to let you dive in at exactly the level of involvement that you
desire.

Here are some of the capabilities of the module; almost all of these are optional,
so you are free to pick and choose which ones suit your needs:

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

Examples
--------
In the `tests` directory, there are example manifests that show how you can
do a basic setup in a few different configurations.  They include examples of
setting up PuppetDB and all of its dependencies all on the same node as your
Puppet master, and also an example of a 3-node distributed setup in which
Puppet, PuppetDB, and PostgreSQL are all running on separate machines.

Also, see `README_GETTING_STARTED.md` for a little more of a guided tour.

Resource Overview
-----------------

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

##### `puppetdb::database::postgresql` class

This is a class for managing a postgresql server for use by PuppetDB.  It can
manage the postgresql packages and service, as well as creating and managing the
puppetdb database and database user accounts.

##### Low-level classes

There are several lower-level classes in the module (e.g., `puppetdb::master::*`
and `puppetdb::server::*` which you can use to manage individual configuration
files or other parts of the system.  In the interest of brevity, we’ll skip over
those for now... but if you need more fine-grained control over your setup, feel
free to dive into the module and have a look!)
