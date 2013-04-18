How installation works
----------------------

While version 2.0 of Fuel provided the ability to simplify installation of OpenStack, version 2.1 includes orchestration capabilities that simplify deployment an OpenStack cluster.  The deployment process follows this general procedure:

#.  Design your architecture.
#.  Install Fuel onto the fuel-pm machine.
#.  Configure Fuel.
#.  Create the basic configuration and load it into Cobbler.
#.  PXE-boot the servers so Cobbler can install the operating system.
#.  Use Fuel's included templates and the configuration to populate Puppet's site.pp file.
#.  Customize the site.pp file if necessary.
#.  Use the orchestrator to coordinate the installation of the appropriate OpenStack components on each node.

Start by designing your architecture.

