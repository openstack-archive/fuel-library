OpenStack Networking HA
-----------------------

Fuel 2.1 introduces support for OpenStack Networking (formerly known as Quantum) in a high-availability configuration. To accomplish this, Fuel uses a combination of Pacemaker and Corosync to ensure that if the networking service goes down, it will be restarted, either on the existing node or on separate node.

This document explains how to configure these options in your own installation.

