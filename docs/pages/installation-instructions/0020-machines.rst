
Machines
--------

At the very minimum, you need to have the following machines in your data center:

* 1x Puppet master and Cobbler server (called "fuel-pm", where "pm" stands for puppet master). You can also choose to have Puppet master and Cobbler server on different nodes
* 3x for OpenStack controllers (called "fuel-controller-01", "fuel-controller-02", and "fuel-controller-03")
* 1x for OpenStack compute (called "fuel-compute-01")

In case of VirtualBox environment, allocate the following resources for these machines:

* 1+ vCPU
* 512+ MB of RAM for controller nodes
* 1024+ MB of RAM for compute nodes
* 1024+ MB of RAM for Puppet master and Cobbler server node
* 8+ GB of HDD (enable dynamic virtual drive expansion in order to save some disk space)

