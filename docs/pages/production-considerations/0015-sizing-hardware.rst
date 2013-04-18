Sizing Hardware
---------------

One of the first questions that comes to mind when planning an OpenStack deployment is "what kind of hardware do I need?"  Finding the answer is rarely simple, but getting some idea is not impossible.

Many factors contribute to decisions regarding hardware for an OpenStack cluster -- `contact Mirantis <http://www.mirantis.com/contact/>`_ for information on your specific situation -- but in general, you will want to consider the following four areas:

* CPU
* Memory
* Disk
* Networking

Your needs in each of these areas are going to determine your overall hardware requirements.

CPU
^^^

The basic consideration when it comes to CPU is how many GHZ you're going to need.  To determine that, think about how many VMs you plan to support, and the average speed you plan to provide, as well as the maximum you plan to provide for a single VM.  For example, consider a situation in which you expect:

* 100 VMs
* 2 EC2 compute units (2 GHz) average
* 16 EC2 compute units (16 GHz) max

What does this mean?  Well, to make it possible to provide the maximum CPU, you will need at least 5 cores (16 GHz/(2.4 GHz per core * 1.3 for hyperthreading)) per machine, and at least 84 cores ((100 VMs * 2 GHz per VM)/2.4 GHz per core) in total.

If you were to choose the Intel E5 2650-70 8 core CPU, that means you need 10-11 sockets (84 cores / 8 cores per socket).

All of this means you will need 5-6 dual core servers (11 sockets / 2 sockets per server), for a "packing density" of 17 VMs per server (100 VMs / 6 servers).

You will need to take into account a couple of additional notes:

* This model assumes you are not oversubscribing your CPU.
* If you are considering Hyperthreading, count each core as 1.3, not 2.
* Choose a good value CPU.

Memory
^^^^^^

The process of determining memory requirements is similar to determining CPU.  Start by deciding how much memory will be devoted to each VM.  In this example, with 4 GB per VM and a maximum of 32 GB for a single VM, you will need 400 GB of RAM.

For cost reasons, you will want to use 8 GB or smaller DIMMs, so considering 16 - 24 slots per server (or 128 GB at the low end) you will need 4 servers to meet your needs.

However, remember that you need 6 servers to meet your CPU requirements, so instead you can go with 6 64 GB or 96 GB machines.

Again, you do not want to oversubscribe memory.

Disk Space
^^^^^^^^^^

When it comes to disk space there are several types that you need to consider:

* Ephemeral (the local drive space for a VM)
* Persistent (the remote volumes that can be attached to a VM)
* Object Storage (such as images or other objects)

As far as local drive space that must reside on the compute nodes, in our example of 100 VMs, our assumptions are:

* 50 GB local space per VM
* 5 TB total of local space (100 VMs * 50 GB per VM)
* 500 GB of persistent volume space per VM
* 50 TB total persistent storage

Again you have 6 servers, so that means you're looking at .9TB per server (5 TB / 6 servers) for local drive space.

Throughput
~~~~~~~~~~

As far as throughput, that's going to depend on what kind of storage you choose.  In general, you calculate IOPS based on the packing density (drive IOPS * drives in the server / VMs per server), but the actual drive IOPS will depend on what you choose.  For example:

* 3.5" slow and cheap (100 IOPS per drive, with 2 mirrored drives)

   * 100 IOPS * 2 drives / 17 VMs per server = 12 Read IOPS, 6 Write IOPS

* 2.5" 15K (200 IOPS, 4 600 GB drive, RAID 10)

   * 200 IOPS * 4 drives / 17 VMs per server = 48 Read IOPS, 24 Write IOPS

* SSD (40K IOPS, 8 300 GB drive, RAID 10)

   * 40K * 8 drives / 17 VMs per server = 19K Read IOPS, 9.5K Write IOPS

Clearly, SSD gives you the best performance, but the difference in cost between that and the lower end solution is going to be signficant, to say the least.  You'll need to decide based on your own situation.

Remote storage
~~~~~~~~~~~~~~

IOPS will also be a factor in determining how you decide to handle persistent storage.  For example, consider these options for laying out your 50 TB of remote volume space:

* 12 drive storage frame using 3 TB 3.5" drives mirrored

  * 36 TB raw, or 18 TB usable space per 2U frame
  * 3 frames (50 TB / 18 TB per server)
  * 12 slots x 100 IOPS per drive = 1200 Read IOPS, 600 Write IOPS per frame
  * 3 frames x 1200 IOPS per frame / 100 VMs = 36 Read IOPS, 18 Write IOPS per VM

* 24 drive storage frame using 1TB 7200 RPM 2.5" drives

  * 24 TB raw, or 12 TB usable space per 2U frame
  * 5 frames (50 TB / 12 TB per server)
  * 24 slots x 100 IOPS per drive = 2400 Read IOPS, 1200 Write IOPS per frame
  * 5 frames x 2400 IOPS per frame / 100 VMs = 120 Read IOPS, 60 Write IOPS per frame

You can accomplish the same thing with a single 36 drive frame using 3 TB drives, but this becomes a single point of failure in your cluster.

Object storage
~~~~~~~~~~~~~~

When it comes to object storage, you will find that you need more space than you think.  For example, this example specifies 50 TB of object storage.  Easy right?

Well, no.  Object storage uses a default of 3 times the required space for replication, which means you will need 150 TB.  However, to accommodate two hands-off zones, you will need 5 times the required space, which means 250 TB.

But the calculations don't end there.  You don't ever want to run out of space, so "full" should really be more like 75% of capacity, which means 333 TB, or a multiplication factor of 6.66.

Of course, that might be a bit much to start with; you might want to start with a happy medium of a multiplier of 4, then acquire more hardware as your drives begin to fill up.  That means 200 TB in this example.

So how do you put that together?  If you were to use 3 TB 3.5" drives, you could use a 12 drive storage frame, with 6 servers hosting 36 TB each (for a total of 216 TB).

You could also use a 36 drive storage frame, with just 2 servers hosting 108 TB each, but it's not recommended due to several factors, from the high cost of failure to replication and capacity issues.

Networking
^^^^^^^^^^

Perhaps the most complex part of designing an OpenStack cluster is the networking.  An OpenStack cluster can involve multiple networks even beyond the Public, Private, and Internal networks.  Your cluster may involve tenant networks, storage networks, multiple tenant private networks, and so on.  Many of these will be VLANs, and all of them will need to be planned out.

In terms of the example network, consider these assumptions:

* 100 Mbits/second per VM
* HA architecture
* Network Storage is not latency sensitive

In order to achieve this, you can use 2 1Gb links per server (2 x 1000 Mbits/second / 17 VMs = 118 Mbits/second).  Using 2 links also helps with HA.

You can also increase throughput and decrease latency by using 2 10 Gb links, bringing the bandwidth per VM to 1 Gb/second, but if you're going to do that, you've got one more factor to consider.

Scalability and oversubscription
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

It is one of the ironies of networking that 1Gb Ethernet generally scales better than 10Gb Ethernet -- at least until 100Gb switches are more commonly available.  It's possible to aggregate the 1Gb links in a 48 port switch, so that you have 48 1Gb links down, but 4 10GB links up.  Do the same thing with a 10Gb switch, however, and you have 48 10Gb links down and 4 100Gb links up, resulting in oversubscription.

Like many other issues in OpenStack, you can avoid this problem to a great extent with careful planning.  Problems only arise when you are moving between racks, so plan to create "pods", each of which includes both storage and compute nodes.  Generally, a pod is the size of a non-oversubscribed L2 domain.

Hardware for this example
~~~~~~~~~~~~~~~~~~~~~~~~~

In this example, you are looking at:

* 2 data switches (for HA), each with a minimum of 12 ports for data (2 x 1Gb links per server x 6 servers)
* 1 1Gb switch for IPMI (1 port per server x 6 servers)
* Optional Cluster Management switch, plus a second for HA

Because your network will in all likelihood grow, it's best to choose 48 port switches.  Also, as your network grows, you will need to consider uplinks and aggregation switches.

Summary
^^^^^^^

In general, your best bet is to choose a large multi-socket server, such as a 2 socket server with a balance in I/o, CPU, Memory, and Disk.  Look for a 1U low cost R-class or 2U high density C-class server.  Some good alternatives for compute nodes include:

* Dell PowerEdge R620
* Dell PowerEdge C6220 Rack Server
* Dell PowerEdge R720XD (for high disk or IOPS requirements)
