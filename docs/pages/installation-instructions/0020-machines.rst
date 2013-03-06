Infrastructure allocation
-------------------------

The next step is to make sure that you have all of the required
hardware and software in place.


Software
^^^^^^^^

You can download the latest release of Fuel here:



[LINK HERE]


Additionally, you can download a pre-built Puppet Master/Cobbler ISO,
which will cut down the amount of time you'll need to spend getting
Fuel up and running. You can download the ISO here:

[LINK HERE]


Hardware for a virtual installation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For a virtual installation, you need only a single machine. You can get
by on 8GB of RAM, but 16GB will be better. To actually perform the
installation, you need a way to create Virtual Machines. This guide
assumes that you are using the latest version of VirtualBox (currently
4.2.6), which you can download from



`https://www.virtualbox.org/wiki/Downloads`



You'll need to run VirtualBox on a stable host system. Mac OS 10.7.x,
CentOS 6.3, or Ubuntu 12.04 are preferred; results in other operating 
systems are unpredictable.



You will need to allocate the following resources:




* 1 server to host both Puppet Master and Cobbler. The minimum configuration for this server is:
    * 32-bit or 64-bit architecture
    * 1+ CPU or vCPU
    * 1024+ MB of RAM
    * 16+ GB of HDD for OS, and Linux distro storage


* 3 servers to act as OpenStack controllers (called fuel-controller-01, fuel-controller-02, and fuel-controller-03). The minimum configuration for a controller in Swift Compact mode is:    * 64-bit architecture

    * 1+ CPU 1024+ MB of RAM
    * 8+ GB of HDD for base OS
    * 10+ GB of HDD for Swift

* 1 server to act as the OpenStack compute node (called fuel-compute-01). The minimum configuration for a compute node with Cinder deployed on it is:
    * 64-bit architecture
    * 2+ CPU, with Intel VTx or AMDV virtualization technology
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
    * 1+ CPU or vCPU
    * 1024+ MB of RAM
    * 16+ GB of HDD for OS, and Linux distro storage

* 3 servers to act as OpenStack controllers (called fuel-controller-01, fuel-controller-02, and fuel-controller-03). The   minimum configuration for a controller in Swift Compact mode is:
    * 64-bit architecture
    * 1+ CPU
    * 1024+ MB of RAM
    * 400+ GB of HDD

* 1 server to act as the OpenStack compute node (called fuelcompute-01). The minimum configuration for a compute node with Cinder deployed on it is:
    * 64-bit architecture
    * 2+ CPU, with Intel VTx or AMDV virtualization technology
    * 2048+ MB of RAM
    * 1+ TB of HDD




(If you choose to deploy Quantum on a separate node, you will need an
additional server with specifications comparable to the controller
nodes.)



For a list of certified hardware configurations, please contact the
Mirantis Services team.
