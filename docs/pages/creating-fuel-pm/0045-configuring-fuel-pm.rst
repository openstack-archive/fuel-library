.. _Configuring-Fuel-PM:

Configuring fuel-pm
--------------------------------
Once the installation is complete, you will need to finish the configuration to adjust for your own local values.

* Check network settings and connectivity and correct any errors:

    * Check the hostname. Running ::

        hostname

      should return ::

        fuel-pm

      If not, set the hostname:



      ``vi /etc/sysconfig/network`` ::

           HOSTNAME=fuel-pm



    * Check the fully qualified hostname (FQDN) value. ::

          hostname -f

      should return ::

          fuel-pm.localdomain

      If not, correct the ``/etc/resolv.conf`` file by replacing ``localdomain`` below with your actual domain name, and ``8.8.8.8`` with your actual DNS server.

      (Note: you can look up your DNS server on your host machine using ``ipconfig /all`` on Windows, or using ``cat /etc/resolv.conf`` under Linux) ::

          search localdomain
          nameserver 8.8.8.8

    * Run ::

          hostname fuel-pm

      or reboot to apply changes to the hostname.


    * Add the OpenStack hostnames to your domain. You can do this by actually adding them to DNS, or by simply editing the /etc/hosts file.  In either case, replace localdomain with your domain name.

      ``vi /etc/hosts``::

          127.0.0.1 localhost
          10.0.0.100 fuel-pm.localdomain fuel-pm
          10.0.0.101 fuel-controller-01.localdomain fuel-controller-01
          10.0.0.102 fuel-controller-02.localdomain fuel-controller-02
          10.0.0.103 fuel-controller-03.localdomain fuel-controller-03
          10.0.0.110 fuel-compute-01.localdomain fuel-compute-01


Enabling Stored Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Fuel's Puppet manifests call for storing exported resources in the
Puppet database using PuppetDB, so the next step is to configure
Puppet to use a technique called stored configuration.




* Configure Puppet Master to use storeconfigs:


    ``vi /etc/puppet/puppet.conf`` and add following into the ``[master]`` section::

        storeconfigs = true
        storeconfigs_backend = puppetdb

* Configure PuppetDB to use the correct hostname and port:

     ``vi /etc/puppet/puppetdb.conf`` to create the ``puppetdb.conf`` file and add the following (replace ``localdomain`` with your domain name)::

          [main]
          server = fuel-pm.localdomain
          port = 8081

* Configure Puppet Master's file server capability:

    ``vi /etc/puppet/fileserver.conf`` and append the following lines::

          [ssh_keys]
          path /var/lib/puppet/ssh_keys
          allow *




* Create a directory with keys, give it appropriate permissions, and generate the keys themselves::


    mkdir /var/lib/puppet/ssh_keys
    cd /var/lib/puppet/ssh_keys
    ssh-keygen -f openstack
    chown -R puppet:puppet /var/lib/puppet/ssh_keys/




* Set up SSL for PuppetDB and restart the puppetmaster and puppetdb services::


    service puppetmaster restart
    puppetdb-ssl-setup
    service puppetmaster restart
    service puppetdb restart



* Finally, if you are planning to install Cobbler on the Puppet Master node as well (as we are in this example), make configuration changes on the Puppet Master so that it actually knows how to provision software onto itself:

  ``vi /etc/puppet/puppet.conf``::


     [main]
     # server
     server = fuel-pm.localdomain

     # enable plugin sync
     pluginsync = true


* **IMPORTANT**: Note that while these operations appear to finish quickly, it can actually take several minutes for puppetdb to complete its startup process. You'll know it has finished starting up when you can successfully telnet to port 8081::

     yum install telnet
     telnet fuel-pm.localdomain 8081


Testing Puppet
^^^^^^^^^^^^^^


Add a simple configuration to Puppet so that when you run puppet on various nodes,
it will display a "Hello world" message:

``vi /etc/puppet/manifests/site.pp``::


    node /fuel-pm.localdomain/ {
        notify{"Hello world from fuel-pm": }
    }




Finally, to make sure everything is working properly, run puppet agent
and to see the ``Hello World from fuel-pm`` output::

    puppet agent --test




Troubleshooting PuppetDB and SSL
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The first time you run puppet, its not unusual to have difficulties
with the SSL setup. If so, remove the original files and start again,
like so::


    sudo service puppetmaster stop
    sudo service puppetdb stop
    sudo rm -rf /etc/puppetdb/ssl
    sudo puppetdb-ssl-setup
    sudo service puppetdb start
    sudo service puppetmaster start

Again, remember that it may take several minutes before puppetdb is
fully running, despite appearances to the contrary.
