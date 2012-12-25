
Deploying OpenStack
-------------------

Initial setup
~~~~~~~~~~~~~

If you are using hardware, make sure it is capable of PXE booting over the network from Cobbler.

In case of VirtualBox, create the corresponding virtual machines for your OpenStack nodes in VirtualBox. Do not start them yet.

* Machine -> New...
    * Name: fuel-controller-01 (will need to repeat for fuel-controller-02, fuel-controller-03, and fuel-compute-01)
    * Type: Linux
    * Version: Red Hat (64 Bit)

* Machine -> Settings... -> Network
    * Adapter 1
        * Enable Network Adapter
        * Attached to: Bridged Adapter
        * Name: en1 (Wi-Fi Airport), or whatever network interface of the host machine where you have Internet access 

    * Adapter 2
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet0

    * Adapter 3
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet1
        * Advanced -> Promiscuous mode: Allow All

Configuring Cobbler to provision your OpenStack nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now you need to define nodes in the Cobbler configuration, so that it knows what OS to install, where to install it, and what configuration actions to take.

On Puppet master, create a directory with configuration and copy the sample config file for Cobbler from Fuel repository:

    * ``mkdir cobbler_config``
    * ``cd cobbler_config``
    * ``ln -s ../fuel/deployment/puppet/cobbler/examples/cobbler_system.py .``
    * ``cp ../fuel/deployment/puppet/cobbler/examples/nodes.yaml .``

Edit configuration for bare metal provisioning of nodes (nodes.yaml):

* There is essentially a section for every node, and you have to define all nodes there (fuel-controller-01, fuel-controller-02, fuel-controller-03, and fuel-compute-04). The config for a single node is given below, while the config for the remaining nodes is very similar
* It is important to get the following parameters correctly specified (they are different for every node):
    * Name of the system in Cobbler, the very first line
    * Hostname and DNS name
    * MAC addresses for every network interface (you can look them up in VirtualBox, using Machine -> Settings... -> Network -> Adapters)
    * Static IP address on management interface eth1
* vi nodes.yaml
    .. literalinclude:: ../../deployment/puppet/cobbler/examples/nodes.yaml

* For the sake of convenience the "./cobbler_system.py" script is provided: it reads the definition of the systems from the yaml file and makes calls to Cobbler API to insert these systems into the configuration. Run it using the following command:
    * ``./cobbler_system.py -f nodes.yaml -l DEBUG``

Provisioning your OpenStack nodes using Cobbler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now, when Cobbler has the correct configuration, the only thing you need to do is to PXE-boot your nodes. They will boot over the network from DHCP/TFTP provided by Cobbler and will be provisioned accordingly, with the specified operating system and configuration.

In case of VirtualBox, here is what you have to do for every virtual machine (fuel-controller-01, fuel-controller-02, fuel-controller-03, fuel-compute-04):

* disable bridged network adapter by unchecking  "Machine -> Settings -> Network -> Enable Network Adapter" 
    * Reason for that: by default, VirtualBox will attempt to use the first network interface for PXE-boot and it is going to fail. We actually want our machines to PXE-boot from Cobbler which is on 10.0.0.100 (first host-only adapter). So the solution is to temporarily disable "bridged network adapter".
* Machine -> Start
* press F12 during boot and select "l" (LAN) as a bootable media
* once installation is complete:
    * log into the machine (l: root, p: r00tme)
    * perform shutdown using "``shutdown -H now``"
* enable back the bridged network adapter by checking "Machine -> Settings -> Network -> Enable Network Adapter"
* start the node using VirtualBox
* check that the network works correctly
    * ``ping www.google.com``
    * ``ping 10.0.0.100``

It is important to note that if you use VLANs in your network configuration, you always have to keep in mind the fact that PXE booting does not work on tagged interfaces. Therefore, all your nodes including the one where the Cobbler service resides must share one untagged VLAN (also called "native VLAN"). You can use ``dhcp_interface`` parameter of the ``cobbler::server`` class to bind a DHCP service to a certain interface.

Now you have OS installed and configured on all nodes. Moreover, Puppet is installed on the nodes as well and its configuration points to our Puppet master. Therefore, the nodes are almost ready for deploying OpenStack. Now, as the last step, you need to register nodes in Puppet master:

* ``puppet agent --test``
    * it will generate a certificate, send it to Puppet master for signing, and then fail
* switch to Puppet master and execute:
    * ``puppet cert list``
    * ``puppet cert sign --all``
        * alternatively, you can sign only a single certificate using "puppet cert sign fuel-XX.mirantis.com"
* ``puppet agent --test``
    * it should successfully complete and result in the "Hello world" message

Installing OpenStack
~~~~~~~~~~~~~~~~~~~~

In case of VirtualBox, it is recommended to save the current state of every virtual machine using the mechanism of snapshots. It is helpful to have a point to revert to, so that you could install OpenStack using Puppet and then revert and try one more time, if necessary.

* In Puppet master
    * Create a file with the definition of networks, nodes, and roles. Assume you are deploying a compact configuration, with Controllers and Swift combined:
        * ``cp fuel/deployment/puppet/openstack/examples/site_openstack_swift_compact.pp /etc/puppet/manifests/site.pp``
    * ``vi /etc/puppet/manifests/site.pp``
        .. literalinclude:: ../../deployment/puppet/openstack/examples/site_openstack_swift_compact.pp
    * Create directory ``/var/lib/puppet/ssh_keys`` and do ``ssh-keygen -f openstack`` there
    * Edit file ``/etc/puppet/fileserver.conf`` and append the following lines there: ::

        [ssh_keys]
        path /var/lib/puppet/ssh_keys
        allow *

* Install OpenStack controller nodes sequentially, one by one
    * run "``puppet agent --test``" on fuel-controller-01
    * wait for the installation to complete
    * repeat the same for fuel-controller-02 and fuel-controller-03
    * .. Important:: It is important to establish the cluster of OpenStack controllers in sequential fashion, due to the nature of assembling MySQL cluster based on Galera

* Install OpenStack compute nodes, you can do it in parallel if you want
    * run "``puppet agent --test``" on fuel-compute-01
    * wait for the installation to complete

* Your OpenStack cluster is ready to go.

Note: Due to the Swift setup specifics, it is not enough to run Puppet 1 time. To complete the deployment, you should perform 3 runs of Puppet on each node.

