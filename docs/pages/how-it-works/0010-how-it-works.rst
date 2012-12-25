
Fuel provides the following important bits in order to streamline the process of installing and managing OpenStack: 

* Automation & instructions to install master node with Puppet Master and Cobbler
* Snippets, kickstart and preseed files for Cobbler
* Puppet manifests for all OpenStack components

In order to use Fuel, one should create a master node first. Then a configuration should be supplied for an OpenStack installation -- the description of physical nodes, layout of OpenStack components, as well as desired OpenStack settings. After that Fuel automatically performs the deployment procedure according to the reference architecture with built-in high availability for OpenStack components. It performs bare metal provisioning of hardware nodes first, and then does the installation and setup of an OpenStack cloud:

.. image:: https://docs.google.com/drawings/pub?id=15vTTG2_575M7-kOzwsYyDmQrMgCPT2joLF2Cgiyzv7Q&w=678&h=617

