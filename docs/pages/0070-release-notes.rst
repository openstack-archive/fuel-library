Release Notes
=============

.. contents:: :local:


v0.2.0-folsom
-------------

* Puppet manifests for deploying OpenStack Folsom in HA mode
* Active/Active HA architecture for Folsom, based on RabbitMQ / MySQL Galera / HAProxy / keepalived
* Added support for Ubuntu 12.04 in addition to CentOS 6.3 and RHEL 6.3 (includes bare metal provisioning, Puppet manifests, and OpenStack packages)
* Supports deploying Folsom with Quantum/OVS
* Supports deploying Folsom with Cinder 
* Supports Puppet 2.7 and 3.0  


v0.1.0-essex
------------

* Puppet manifests for deploying OpenStack Essex in HA mode
* Active/Active HA architecture for Essex, based on RabbitMQ / MySQL Galera / HAProxy / keepalived
* Cobbler-based bare-metal provisioning for CentOS 6.3 and RHEL 6.3
* Access to the mirror with OpenStack packages (http://download.mirantis.com/epel-fuel/)
* Configuration templates for different OpenStack cluster setups
* User Guide

