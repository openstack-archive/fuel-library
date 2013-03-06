Testing OpenStack
-----------------

Now that you've installed OpenStack, its time to take your new
openstack cloud for a drive. Follow these steps:




#. On the host machine, open your browser to




http://10.0.1.10/



and login as nova/nova (unless you changed this information in
site.pp)


#. In the network and security groups tab:


    #. Create a new key/pair for future use
    #. Add tcp 22 22 to default network setting
    #. Add icmp -1 -1 to default network settings
    #. Allocate 2 floating ips for future use





#. The next step is to upload an image to use for creating VMs, but an
   OpenStack bug prevents you from doing this in the browser. Instead,
   log in to any of the controllers as root and execute the following
   commands::




    ~/source openrc
    glance image-create --name cirros --container-format bare --disk-format qcow2 --is-public yes --location https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img


#. Go back to the browser and launch a new instance of this image
   using the tiny flavor.
#. On the instances page:



    #. Click the image and look at the settings.
    #. Click the logs tab to look at the logs.
    #. Click the VNC tab to log in. If you see just a big black rectangle, the machine is in screensaver mode; click the grey area and press the space bar to wake it up, then login as cirros/cubswin:).
    #. Do ifconfig -a | more and see the assigned ip address.
    #. Do sudo fdisk -l and see the disk. Notice that there arent any; no volume has yet been assigned to this VM.



#. Assign a floating ip address to your instance.
#. From your host machine, ping the floating ip assigned to this VM.
#. If that works, you can try to ssh cirros@floating-ip from the host machine.
#. Back in the browser, go to the volumes tab and create a new volume, then attach it to the instance.
#. Go back to the VNC tab and repeat fdisk -l and see the new unpartitioned disk attached.




From here, your new VM is ready to be used.

