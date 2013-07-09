Installing Fuel and Cobbler
--------------------------------

Cobbler performs bare metal provisioning and initial installation of
Linux on OpenStack nodes. Luckily, you already have a Puppet Master
installed and Fuel includes instructions for installing Cobbler, so
you can install Cobbler using Puppet in a few seconds, rather than
doing it manually.


Installing Fuel
^^^^^^^^^^^^^^^

Installing Fuel is a simple matter of copying the complete Fuel
package to fuel-pm and unpacking it in the proper location in order to
supply Fuel manifests to Puppet::



    tar -xzf <fuel-archive-name>.tar.gz
    cd <fuel-archive-name>
    cp -Rf deployment/puppet/* /etc/puppet/modules/
    service puppetmaster restart



From here, using Fuel is a matter of making sure it has the
appropriate site.pp file from the Fuel distribution.


Using Puppet to install Cobbler
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

On fuel-pm, copy the contents of ::



    <FUEL_DIR>/deployment/puppet/cobbler/examples/site.pp



into your existing ::



    /etc/puppet/manifests/site.pp



file. The file has its own documentation, so it's a good idea to look through it to get a feel for the big picture and understand what's going on. The general idea is that this file sets
certain parameters such as networking information, then defines the OS
distributions Cobbler will serve so they can be imported into Cobbler
as it's installed.



Lets take a look at some of the major points, and highlight where you
will need to make changes::



    ...
    # [server] IP address that will be used as address of cobbler server.
    # It is needed to download kickstart files, call cobbler API and
    # so on. Required.
    $server = '10.0.0.100'



This, remember, is the fuel-pm server, which is acting as both the
Puppet Master and Cobbler servers. ::



    # Interface for cobbler instances
    $dhcp_interface = 'eth0'



The Cobbler instance needs to provide DHCP to each of the new nodes,
so you will need to specify which interface will handle that. ::




    $dhcp_start_address = '10.0.0.110'
    $dhcp_end_address = '10.0.0.126'



Change the ``$dhcp_start_address`` and ``$dhcp_end_address`` to match the network allocations you made
earlier. The important thing is to make sure there are no conflicts with the static IPs you are allocating. ::



    $dhcp_netmask = '255.255.255.0'
    $dhcp_gateway = '10.0.0.100'
    $domain_name = 'localdomain'



Change the ``$domain_name`` to your own domain name. ::



    $name_server = '10.0.0.100'
    $next_server = '10.0.0.100'
    $cobbler_user = 'cobbler'
    $cobbler_password = 'cobbler'
    $pxetimeout = '0'

    # Predefined mirror type to use: custom or default (should be removed soon)
    $mirror_type = 'default'



**Change the $mirror_type to be default** so Fuel knows to request
resources from Internet sources rather than having to set up your own
internal repositories.



The next step is to define the node itself, and the distributions it
will serve. ::


    ...
    type => $mirror_type,
    }
    
    node fuel-pm{

        class {'cobbler::nat': nat_range => $nat_range}
    ...



The file assumes that you're installing Cobbler on a separate machine.
Since you're installing it on fuel-pm, change the node name here.



Next, you will need to uncomment the required OS distributions so that
they can be downloaded and imported into Cobbler during Cobbler
installation.



In this example we'll focus on CentOs, so uncomment these lines and
change the location of ISO image files to either a local mirror or the
fastest available Internet mirror for CentOS-6.4-x86_64-minimal.iso::



    ...
    # CentOS distribution
    # Uncomment the following section if you want CentOS image to be downloaded and imported into Cobbler
    # Replace "http://address/of" with valid hostname and path to the mirror where the image is stored

    Class[cobbler::distro::centos64_x86_64] ->
    Class[cobbler::profile::centos64_x86_64]

    class { cobbler::distro::centos64_x86_64:
        http_iso => "http://address/of/CentOS-6.4-x86_64-minimal.iso",
        ks_url => "cobbler",
        require => Class[cobbler],
    }

    class { cobbler::profile::centos64_x86_64: }

    # Ubuntu distribution
    # Uncomment the following section if you want Ubuntu image to be downloaded and imported into Cobbler
    # Replace "http://address/of" with valid hostname and path to the mirror where the image is stored
    ...



If you want Cobbler to serve Ubuntu or RedHat distributions in
addition to CentOS, perform the same actions for those sections.



With those changes in place, Puppet knows that Cobbler must be
installed on the fuel-pm machine, and will also add the right distro and profile. The CentOS
image will be downloaded from the mirror and imported into Cobbler as
well.



Note that while we've set up the network so that external resources are
accessed through the 10.0.1.0/24 network, this configuration includes
Puppet commands to configure forwarding on the Cobbler node to make
external resources available via the 10.0.0.0/24 network, which is used
during the installation process (see enable_nat_all and
enable_nat_filter).



Finally, run the puppet agent to actually install Cobbler on fuel-pm::

    puppet agent --test




Testing cobbler
^^^^^^^^^^^^^^^

You can check that Cobbler is installed successfully by opening the
following URL from your host machine:



http://fuel-pm/cobbler_web/ (u: cobbler, p: cobbler)



If fuel-pm doesn't resolve on your host machine, you can access the
Cobbler dashboard from:



http://10.0.0.100/cobbler_web



At this point you should have a fully working instance of Cobbler,
fully configured and capable of installing the chosen OS (CentOS 6.4 or Ubuntu 12.04) on
the target OpenStack nodes.
