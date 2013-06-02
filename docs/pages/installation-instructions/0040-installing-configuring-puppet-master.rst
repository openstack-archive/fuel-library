
Installing & Configuring Fuel
-----------------------------
Now that you know what you're going to install and where you're going to
install it, it's time to begin putting the pieces together. To do that,
you'll need to create the Puppet master and Cobbler servers, which will
actually provision and set up your OpenStack nodes.

Installing Puppet Master is a one-time procedure for the entire
infrastructure. Once done, Puppet Master will act as a single point of
control for all of your servers, and you will never have to return to
these installation steps again.

The deployment of the Puppet Master server -- named fuel-pm in these
instructions -- varies slightly between the physical and simulation
environments. In a physical infrastructure, fuel-pm must have a
network presence on the same network the physical machines will
ultimately PXE boot from. In a simulation environment fuel-pm only
needs virtual network (hostonlyif) connectivity.

At this point, you should have either a physical or virtual machine that
can be booted from the Mirantis ISO, downloaded from http://fuel.mirantis.com/your-downloads/ .

This ISO can be used to create fuel-pm on a physical or virtual
machine based on CentOS6.4x86_64minimal.iso. If for some reason you
can't use this ISO, follow the instructions in :ref:`Creating the Puppet master <Create-PM>` to create
your own fuel-pm, then skip ahead to :ref:`Configuring fuel-pm <Configuring-Fuel-PM>`.





