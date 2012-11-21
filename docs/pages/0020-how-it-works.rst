How It Works
============

.. contents:: :local:

Fuel provides the following bits and pieces:

* Snippets & kickstart files for Cobbler
* Puppet manifests for all OpenStack components

In order to use Fuel, one must supply configuration -- description of physical nodes, layout of OpenStack components, as well as desired OpenStack settings. After that Fuel automatically performs deployment according to the reference architecture with built-in high availability for OpenStack components.

After configuration is in place, Fuel automatically performs bare metal provisioning of hardware nodes and setup of OpenStack cloud:

.. image:: https://docs.google.com/drawings/pub?id=15vTTG2_575M7-kOzwsYyDmQrMgCPT2joLF2Cgiyzv7Q&w=678&h=617

