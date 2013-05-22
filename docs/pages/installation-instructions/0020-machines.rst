Infrastructure allocation
-------------------------

The next step is to make sure that you have all of the required
hardware and software in place.


Software
^^^^^^^^

You can download the latest release of the Fuel ISO from http://fuel.mirantis.com/your-downloads/.

Alternatively, if you can't use the pre-built ISO, Mirantis also offers the Fuel Library as a tar.gz file downloadable from `Downloads <http://fuel.mirantis.com/your-downloads/>`_ section of the Fuel portal.


Hardware for a virtual installation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For a virtual installation, you need only a single machine. You can get
by on 8GB of RAM, but 16GB will be better. 

To actually perform the
installation, you need a way to create Virtual Machines. This guide
assumes that you are using version 4.2.6 of VirtualBox, which you can download from

https://www.virtualbox.org/wiki/Downloads

Make sure to also install the Extension Pack.

You'll need to run VirtualBox on a stable host system. Mac OS 10.7.x,
CentOS 6.3, or Ubuntu 12.04 are preferred; results in other operating 
systems are unpredictable.

You will need to allocate the following resources:

* 1 server to host both Puppet Master and Cobbler. The minimum configuration for this server is:

    * 32-bit or 64-bit architecture
    * 1+ CPU or vCPU
    * 1024+ MB of RAM
    * 16+ GB of HDD for OS, and Linux distro storage

* 3 servers to act as OpenStack controllers (called fuel-controller-01, fuel-controller-02, and fuel-controller-03). The minimum configuration for a controller in Compact mode is: 

    * 64-bit architecture
    * 1+ CPU 1024+ MB of RAM
    * 8+ GB of HDD for base OS
    * 10+ GB of HDD for Swift

* 1 server to act as the OpenStack compute node (called fuel-compute-01). The minimum configuration for a compute node with Cinder deployed on it is:
    * 64-bit architecture
    * 2048+ MB of RAM
    * 50+ GB of HDD for OS, instances, and ephemeral storage
    * 50+ GB of HDD for Cinder

Instructions for creating these resources will be provided in :ref:`Installing the OS using Fuel <Install-OS-Using-Fuel>`.


Hardware for a physical infrastructure installation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The amount of hardware necessary for an installation depends on the
choices you have made above. This sample installation requires the
following hardware:

* 1 server to host both Puppet Master and Cobbler. The minimum configuration for this server is:

    * 32-bit or 64-bit architecture
    * 1+ CPU or vCPU for up to 10 nodes (2 vCPU for up to 20 nodes, 4 vCPU for up to 100 nodes)
    * 1024+ MB of RAM for up to 10 nodes (4096+ MB for up to 20 nodes, 8192+ MB for up to 100 nodes)
    * 16+ GB of HDD for OS, and Linux distro storage

* 3 servers to act as OpenStack controllers (called fuel-controller-01, fuel-controller-02, and fuel-controller-03). The   minimum configuration for a controller in Compact mode is:

    * 64-bit architecture
    * 1+ CPU
    * 1024+ MB of RAM
    * 400+ GB of HDD

* 1 server to act as the OpenStack compute node (called fuel-compute-01). The minimum configuration for a compute node with Cinder deployed on it is:

    * 64-bit architecture
    * 2+ CPU, with Intel VTx or AMDV virtualization technology
    * 2048+ MB of RAM
    * 1+ TB of HDD

(If you choose to deploy Quantum on a separate node, you will need an
additional server with specifications comparable to the controller
nodes.)

For a list of certified hardware configurations, please `contact the
Mirantis Services team <http://www.mirantis.com/contact/>`_.

Providing the OpenStack nodes
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you are using hardware, make sure it is capable of PXE booting over
the network from Cobbler. You'll also need each server's mac address.



If you're using VirtualBox, you will need to create the corresponding
virtual machines for your OpenStack nodes. Follow these instructions
to create machines named fuel-controller-01, fuel-controller-02, fuel-
controller-03, and fuel-compute-01, but do not start them yet.



As you create each network adapter, click Advanced to expose and
record the corresponding mac address.




* Machine -> New...



    * Name: fuel-controller-01 (you will need to repeat these steps for fuel-controller-02, fuel-controller-03, and fuel-compute-01)
    * Type: Linux
    * Version: Red Hat (64 Bit)
    * Memory: 1024MB



* Machine -> System -> Motherboard...

    * Check Network in Boot sequence

* Machine -> Settings -> Storage

    * Controller: SATA

        * Click the Add icon at the bottom of the Storage Tree pane
        * Add a second VDI disk of 10GB for storage

* Machine -> Settings... -> Network



    * Adapter 1



        * Enable Network Adapter
        * Attached to: Hostonly Adapter
        * Name: vboxnet0



    * Adapter 2



        * Enable Network Adapter
        * Attached to: Bridged Adapter
        * Name: eth0 (physical network attached to the Internet.  You can also use a gateway.)



    * Adapter 3

        * Enable Network Adapter
        * Attached to: Hostonly Adapter
        * Name: vboxnet2
        * Advanced -> Promiscuous mode: Allow All


It is important that hostonly Adapter 1 goes first, as Cobbler will
use vboxnet0 for PXE, and VirtualBox boots from LAN on the first
available network adapter.

The additional drive volume will be used as storage space by Cinder, and will be configured automatically by Fuel.



