
Cluster Sizing
--------------

This reference architecture is well suited for production-grade OpenStack deployments on a medium and large scale, where you can afford to allocate several servers for your OpenStack controller nodes in order to build a fully redundant and highly available environment.

The absolute minimum requirement for a highly-available OpenStack deployment is to allocate 4 nodes:

* 3 controller nodes, combined with storage
* 1 compute node


.. image:: https://docs.google.com/drawings/pub?id=1So4NbE1cLV0X-qDL5QPz6oobH3NHXVsmINmfTmirehk&w=800&h=465


If you want to run storage separately from controllers, you can do that as well by raising the bar to 7 nodes:

* 3 controller nodes
* 3 storage nodes
* 1 compute node


.. image:: https://docs.google.com/drawings/pub?id=1BhMtVmCJV1VUf3OSIqgd4lac0_R6hliQT1jVGl-44-w&w=800&h=624


Of course, you are free to choose how to deploy OpenStack based on the amount of hardware available, and based on your goals (whether you want a compute-oriented or a storage-oriented cluster).

For a typical OpenStack compute deployment, you can use this table as a high-level guidance to determine the number of controllers, compute nodes, and storage nodes you should have:

=============  ===========  =======  ==============
# of Machines  Controllers  Compute  Storage
=============  ===========  =======  ==============
4-10           3            1-7      on controllers
11-40          3            5-34     3 (separate)
41-100         4            31-90    6 (separate)
>100           5            >86      9 (separate)
=============  ===========  =======  ==============

