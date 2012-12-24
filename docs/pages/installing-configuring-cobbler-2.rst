Installation Instructions
=========================

.. contents:: :local:


Installing & Configuring Cobbler
--------------------------------

Cobbler is a bare metal provisioning system which performs bare metal provisioning and initial installation of Linux on OpenStack nodes. Luckily, we already have a Puppet master installed, so we can install Cobbler using Puppet in a few seconds instead of doing it manually.

Using Puppet to install Cobbler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

On Puppet master:

* ``vi /etc/puppet/manifests/site.pp``

* Copy the content of "fuel/deployment/puppet/cobbler/examples/site.pp" into "/etc/puppet/manifests/site.pp":
    .. literalinclude:: ../../deployment/puppet/cobbler/examples/site_fordocs.pp

* Make the following changes in that file:
    * Replace IP addresses and ranges according to your network setup. Replace "your-domain-name.com" with your domain name.
    * Uncomment the required OS distributions. They will be downloaded and imported into Cobbler during Cobbler installation.
    * Change the location of ISO image files to either a local mirror or the fastest available Internet mirror.

* Once the configuration is there, Puppet will know that Cobbler must be installed on the fuel-pm machine. Once Cobbler is installed, the right distro and profile will be automatically added to it. OS image will be downloaded from the mirror and put into Cobbler as well.

* It is necessary to note that in the proposed network configuration the snippet above includes Puppet commands to configure forwarding on Cobbler node to make external resources available via the 10.0.0.0/24 network which is used during the installation process (see "enable_nat_all" and "enable_nat_filter")

* run puppet agent to actually install Cobbler on fuel-pm
    * ``puppet agent --test``

Testing cobbler
~~~~~~~~~~~~~~~

* you can check that Cobbler is installed successfully by opening the following URL from your host machine:
    * http://fuel-pm/cobbler_web/ (u: cobbler, p: cobbler)
* now you have a fully working instance of Cobbler. Moreover, it is fully configured and capable of installing the chosen OS (CentOS 6.3, RHEL 6.3, or Ubuntu 12.04) on the target OpenStack nodes
