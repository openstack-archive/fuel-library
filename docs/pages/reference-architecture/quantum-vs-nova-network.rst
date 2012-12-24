Reference Architecture 
======================


Quantum vs. nova-network
------------------------

Quantum is a service which provides "networking as a service" functionality in OpenStack. It has a rich tenant-facing API for defining network connectivity and addressing in the cloud and gives operators the ability to leverage different networking technologies to power their cloud networking.

There are several common deployment use cases for Quantum. Fuel supports the most common of them called "Provider Router with Private Networks". It provides each tenant with one or more private networks, which can communicate with the outside world via a Quantum router. 

In order to deploy Quantum you need to enable it in Fuel configuration, and Fuel will set up an additional node in the OpenStack installation that will act as an L3 router.

