
Installing & Configuring Cobbler
--------------------------------

Cobbler is bare metal provisioning system which will perform initial installation of Linux on OpenStack nodes. Luckily, we already have a Puppet master installed, so we can install Cobbler through Puppet in a matter of seconds rather than do it manually.

Using Puppet to install Cobbler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

On Puppet master:

* ``vi /etc/puppet/manifests/site.pp``
* Copy the content of "fuel/deployment/puppet/cobbler/examples/site.pp" into "/etc/puppet/manifests/site.pp":
    .. literalinclude:: ../../deployment/puppet/cobbler/examples/site.pp

* The only thing you might want to change is the location of CentOS 6.3 ISO image file (to either a local mirror, or the fastest available Internet mirror): ::

    class { cobbler::distro::centos63-x86_64:
        http_iso => "http://mirror.facebook.net/centos/6.3/isos/x86_64/CentOS-6.3-x86_64-minimal.iso",
        ks_url   => "cobbler",
    }

* The file above assumes that you will install CentOS 6.3 as a base OS for OpenStack nodes. If you want to install RHEL 6.3, you will need to download its ISO image from `Red Hat Customer Portal <https://access.redhat.com/home>`_, put it on a local HTTP mirror, and add the following lines to the configuration file: ::

    class { cobbler::distro::rhel63-x86_64:
        http_iso => "http://<local-mirror-ip>/iso/rhel-server-6.3-x86_64-boot.iso",
        ks_url => "http://<local-mirror-ip>/rhel/6.3/os/x86_64",
    }

    Class[cobbler::distro::rhel63-x86_64] ->
    Class[cobbler::profile::rhel63-x86_64]

    class { cobbler::profile::rhel63-x86_64: }
  
* Once the configuration is there, Puppet will know that Cobbler is to be installed on fuel-pm machine. Once Cobbler is installed, the right distro and profile will be automatically added to it. OS image will be downloaded from the mirror and put into Cobbler as well.
* It is necessary to note: in the proposed network configuration, the snippet above includes Puppet commands to configure forwarding on Cobbler node to make external resources available via the 10.0.0.0/24 network which is used during the installation process (see "enable_nat_all" and "enable_nat_filter")
* run Puppet agent to actually install Cobbler on fuel-pm
    * ``puppet agent --test``

Testing Cobbler
~~~~~~~~~~~~~~~

* You can check that Cobbler is installed successfully by opening the following URL from your host machine:
    * http://fuel-pm/cobbler_web (u: cobbler, p: cobbler)
* Now you have a fully working instance of Cobbler. Moreover, it is fully configured and capable of installing the chosen OS (CentOS 6.3, or RHEL 6.3) on the target OpenStack nodes

