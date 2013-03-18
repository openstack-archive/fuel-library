Configuring fuel-pm from the ISO installation
---------------------------------------------

Once fuel-pm finishes installing, you'll be presented with a basic menu:

.. image:: /pages/installation-instructions/screenshots/fuel-iso-menu.png

You can use this menu to set the basic information Fuel will need to configure your installation.  You can customize these steps for your own situation, of course, but here are the steps to take for the example installation:

#. To set the fully-qualified domain name for the master node and cloud domain, choose 1.

   * Type ``fuel-pm`` for the hostname.
   * Set your own domain name.

#. To configure the management interface, choose 2.

   * The example specifies eth1 as the internal, or management interface, so enter that.
   * The management network in the example is using static IP addresses, so specify no for for using DHCP.
   * Enter the IP address of 10.20.0.10 for the Puppet Master, and the netmask of 255.255.255.0.
   * Because this interface is not using DHCP, you'll need to specify the gateway and DNS servers. If you're installing on VirtualBox, the gateway will be the host IP, 10.20.0.1.
   * Enter the first and second DNS servers for your domain.

#. To configure the external interface, which will be used to send traffic to and from the internet, choose 3.  Set the interface to eth0.  By default, this interface uses DHCP, which is what the example calls for.

#. To choose the start and end addresses for compute nodes, choose 4.  In the case of this example, the start address is  10.20.0.201 and the end address is 10.20.0.254.

Future versions of Fuel will enable you to choose a custom set of repositories.

Please note:  You must set actual values; if you simply press "enter" you will wind up with empty values.

5.  Once you've finished editing, choose 6 to save your changes and exit the menu.

To re-enter the menu at any time, type::

  bootstrap_admin_node.sh






