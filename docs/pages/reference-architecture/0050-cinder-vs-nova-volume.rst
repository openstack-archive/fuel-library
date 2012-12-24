
Cinder vs. nova-volume
----------------------

Cinder is a persistent storage management service, also known as "block storage as a service". It was created to replace nova-volume. 

If you decide use persistent storage, you will need to enable Cinder and supply the list of block devices to it. The block devices can be:

* created by Cobbler during the initial node installation
* attached manually (e.g. as additional virtual disks if you are using VirtualBox, or as additional physical RAID, SAN volumes)
