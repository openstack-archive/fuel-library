
Quantum vs. nova-network
^^^^^^^^^^^^^^^^^^^^^^^^

Quantum is a service which provides networking-as-a-service
functionality in OpenStack. It has a rich tenant-facing API for
defining network connectivity and addressing in the cloud, and gives
operators the ability to leverage different networking technologies to
power their cloud networking.



There are various deployment use cases for Quantum. Fuel
supports the most common of them, called Provider Router with Private
Networks. It provides each tenant with one or more private networks,
which can communicate with the outside world via a Quantum router.



Quantum is not, however, required in order to run an OpenStack
cluster; if you don't need (or want) this added functionality, it's
perfectly acceptable to continue using nova-network.



In order to deploy Quantum, you need to enable it in the Fuel
configuration. Fuel will then set up an additional node in the
OpenStack installation to act as an L3 router, or, depending on the configuration options you've chosen, install Quantum on the controllers.
