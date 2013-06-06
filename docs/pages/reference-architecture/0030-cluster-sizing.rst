
Cluster Sizing
^^^^^^^^^^^^^^

This reference architecture is well suited for production-grade
OpenStack deployments on a medium and large scale when you can afford
allocating several servers for your OpenStack controller nodes in
order to build a fully redundant and highly available environment.



The absolute minimum requirement for a highly-available OpenStack
deployment is to allocate 4 nodes:


* 3 controller nodes, combined with storage
* 1 compute node


.. image:: https://docs.google.com/drawings/pub?id=19Dk1qD5V50-N0KX4kdG_0EhGUBP7D_kLi2dU6caL9AM&w=767&h=413


If you want to run storage separately from the controllers, you can do that as well by raising the bar to 7 nodes:

* 3 controller nodes
* 3 storage nodes
* 1 compute node


.. image:: https://docs.google.com/drawings/pub?id=1xmGUrk2U-YWmtoS77xqG0tzO3A47p6cI3mMbzLKG8tY&w=769&h=594


Of course, you are free to choose how to deploy OpenStack based on the
amount of available hardware and on your goals (such as whether you
want a compute-oriented or storage-oriented cluster).



For a typical OpenStack compute deployment, you can use this table as
high-level guidance to determine the number of controllers, compute,
and storage nodes you should have:

=============  ===========  =======  ==============
# of Machines  Controllers  Compute  Storage
=============  ===========  =======  ==============
4-10           3            1-7      on controllers
11-40          3            5-34     3 (separate)
41-100         4            31-90    6 (separate)
>100           5            >86      9 (separate)
=============  ===========  =======  ==============
