
Cinder vs. nova-volume
^^^^^^^^^^^^^^^^^^^^^^

Cinder is a persistent storage management service, also known as block-storage-as-a-service. It was created to replace nova-volume, and
provides persistent storage for VMs.



If you decide use Cinder for persistent storage, you will need to both
enable Cinder and create the block devices on which it will store data.
You will then provide information about those blocks devices during the Fuel
install. (You'll see an example how to do this in section 3.)



Cinder block devices can be:


* created by Cobbler during the initial node installation, or
* attached manually (e.g. as additional virtual disks if you are using VirtualBox, or as additional physical RAID, SAN volumes)





