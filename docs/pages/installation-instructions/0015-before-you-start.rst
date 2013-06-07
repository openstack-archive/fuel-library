
Before you start
----------------

Before you begin your installation, you will need to make a number of important
decisions:

* **OpenStack features.** Your first decision is which of the optional OpenStack features you want. For example, you must decide whether you want to install Swift, whether you want Glance to use Swift for image storage, whether you want Cinder for block storage, and whether you want nova-network or Quantum to handle your network connectivity. In the case of this example, we will be installing Swift, and Glance will be using it. We'll also be using Cinder for block storage. Because it can be easily installed using orchestration, we will also be using Quantum.

* **Deployment configuration.** Next you need to decide whether your deployment requires high availability. If you do choose to do an HA deployment, you have a choice regarding the number of controllers you want to include. Following the recommendations in the previous section for a typical HA deployment configuration, we will use 3 OpenStack controllers.

* **Cobbler server and Puppet Master.** The heart of a Fuel install is the combination of Puppet Master and Cobbler used to create your resources. Although Cobbler and Puppet Master can be installed on separate machines, it is common practice to install both on a single machine for small to medium size clouds, and that's what we'll be doing in this example.  (By default, the Fuel ISO creates a single server with both services.)

* **Domain name.** Puppet clients generate a Certificate Signing Request (CSR), which is then signed by Puppet Master. The signed certificate can then be used to authenticate the client during provisioning. Certificate generation requires a fully qualified hostname, so you must choose a domain name to be used in your installation. Future versions of Fuel will enable you to choose this domain name on your own; by default, Fuel 3.0 uses ``localdomain``.

* **Network addresses.** OpenStack requires a minimum of three networks. If you are deploying on physical hardware, two of them -- the public network and the internal, or management network -- must be routable in your networking infrastructure. Also, if you intend for your cluster to be accessible from the Internet, you'll want the public network to be on the proper network segment.  For simplicity in this case, this example assumes an Internet router at 192.168.0.1.  Additionally, a set of private network addresses should be selected for automatic assignment to guest VMs. (These are fixed IPs for the private network). In our case, we are allocating network addresses as follows:

    * Public network: 192.168.0.0/24
    * Internal network: 10.0.0.0/24
    * Private network: 10.0.1.0/24

* **Network interfaces.** All of those networks need to be assigned to the available NIC cards on the allocated machines. Additionally, if a fourth NIC is available, Cinder or block storage traffic can also be separated and delegated to the fourth NIC. In our case, we're assigning networks as follows:

    * Public network: eth1
    * Internal network: eth0
    * Private network: eth2

