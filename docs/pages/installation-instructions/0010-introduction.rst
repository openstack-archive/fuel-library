In this section, you'll learn how to do an actual installation of
OpenStack using Fuel. In addition to getting a feel for the steps
involved, you'll also gain some familiarity with some of your
customization options. While Fuel does provide several different
deployment topologies out of the box, its common to want to tweak
those architectures for your own situation, so you'll get some practice
moving certain features around from the standard installation.

The first step, however, is to commit to a deployment template. A
fairly balanced small size, yet fully featured, deployment is the
Multi-node (HA) Swift Compact deployment, so that's what we'll be using
through the rest of this guide.

Real world installations require a physical hardware infrastructure,
but you can easily deploy a small simulation cloud on a single
physical machine using VirtualBox. You can follow these instructions
in order to install an OpenStack cloud into a test environment using
VirtualBox, or to get a production-grade installation using actual
hardware.

How installation works
----------------------

In contrast with version 2.0 of Fuel, version 2.1 includes orchestration capabilities that simplify installation of OpenStack.  The process of installing a cluster follows this general procedure:

#.  Design your architecture.
#.  Install Fuel onto the fuel-pm machine.
#.  Configure Fuel.
#.  Create the basic configuration and load it into Cobbler.
#.  PXE-boot the servers so Cobbler can install the operating system.
#.  Use Fuel's included templates and the configuration to populate Puppet's site.pp file.
#.  Customize the site.pp file if necessary.
#.  Use the orchestrator to install the appropriate OpenStack components on each node.

Start by designing your architecture.

Before you start
----------------

Before you begin your installation, you will need to make a number of important
decisions:

* **OpenStack features.** You must choose which of the optional OpenStack features you want. For example, you must decide whether you want to install Swift, whether you want Glance to use Swift for image storage, whether you want Cinder for block storage, and whether you want nova-network or Quantum to handle your network connectivity. In the case of this example, we will be installing Swift, and Glance will be using it. We'll also be using Cinder for block storage. Because it can be easily installed using orchestration, we will also be using Quantum.
* **Deployment topology.** The first decision is whether your deployment requires high availability. If you do choose to do an HA deployment, you have a choice regarding the number of controllers you want to have. Following the recommendations in the previous section for a typical HA topology, we will use 3 OpenStack controllers.
* **Cobbler server and Puppet Master.** The heart of a Fuel install is the combination of Puppet Master and Cobbler used to create your resources. Although Cobbler and Puppet Master can be installed on separate machines, it is common practice to install both on a single machine for small to medium size clouds, and that's what we'll be doing in this example.  (By default, the Fuel ISO creates a single server with both services.)
* **Domain name.** Puppet clients generate a Certificate Signing Request (CSR), which is then signed by Puppet Master. The signed certificate can then be used to authenticate the client during provisioning. Certificate generation requires a fully qualified hostname, so you must choose a domain name to be used in your installation. We'll leave this up to you.
* **Network addresses.** OpenStack requires a minimum of three networks. If you are deploying on physical hardware two of them -- the public network and the internal, or management network -- must be routable in your networking infrastructure. Additionally, a set of private network addresses should be selected for automatic assignment to guest VMs. (These are fixed IPs for the private network). In our case, we are allocating network addresses as follows:

    * Public network: 10.20.1.0/24
    * Internal network: 10.20.0.0/24
    * Private network: 192.168.0.0/16

* **Network interfaces.** All of those networks need to be assigned to the available NIC cards on the allocated machines. Additionally, if a fourth NIC is available, Cinder or block storage traffic can also be separated and delegated to the fourth NIC. In our case, were assigning networks as follows:

    * Public network: eth0
    * Internal network: eth1
    * Private network: eth2

