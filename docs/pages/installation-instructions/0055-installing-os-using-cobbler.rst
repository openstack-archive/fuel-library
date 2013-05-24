.. _Install-OS-Using-Fuel:

Installing the OS using Fuel
----------------------------

The first step in creating the actual OpenStack nodes is to let Fuel's Cobbler kickstart and preseed files assist in the installation of operating systems on the target servers.

Now that Cobbler has the correct configuration, the only thing you
need to do is to PXE-boot your nodes. This means that they will boot over the network, with
DHCP/TFTP provided by Cobbler, and will be provisioned accordingly,
with the specified operating system and configuration.

If you installed Fuel from the ISO, start fuel-controller-01 first and let the installation finish before starting the other nodes; Fuel will cache the downloads so subsequent installs will go faster.

The process for each node looks like this:


#. Start the VM.
#. Press F12 immediately and select l (LAN) as a bootable media.
#. Wait for the installation to complete.
#. Log into the new machine using root/r00tme.
#. **Change the root password.**
#. Check that networking is set up correctly and the machine can reach the Internet::

    ping fuel-pm.localdomain
    ping www.mirantis.com

If you're unable to ping outside addresses, add the fuel-pm server as a default gateway::

    route add default gw 10.20.0.100

**It is important to note** that if you use VLANs in your network
configuration, you always have to keep in mind the fact that PXE
booting does not work on tagged interfaces. Therefore, all your nodes,
including the one where the Cobbler service resides, must share one
untagged VLAN (also called native VLAN). If necessary, you can use the
``dhcp_interface`` parameter of the ``cobbler::server`` class to bind the DHCP
service to the appropriate interface.


