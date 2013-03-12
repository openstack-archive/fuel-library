
Deploying OpenStack
-------------------

At this point you have functioning servers that are ready to have
OpenStack installed. If you're using VirtualBox, save the current state
of every virtual machine by taking a snapshot. (To do that while the
machine is running, highlight the machine in the main VirtualBox
console, click the Snapshots button, then click the camera icon.) This
way you can go back to this point and try again if necessary.



To install the new cluster, the Puppet Master needs a configuration
file that defines all of the appropriate networks, nodes, and roles.
Fortunately, Fuel provides several different configurations, and as we
have discussed, we are going to use the Multi-node (HA) Swift Compact
architecture, or Swift Compact. To configure the Puppet Master to use
the Swift Compact topology, copy that configuration file into the
Puppet Master::



    cp /etc/puppet/modules/openstack/examples/site_openstack_swift_compact.pp /etc/puppet/manifests/site.pp



The next step will be to go through the site.pp file and make any
necessary customizations. In our case, were going to do three things:

#. Customize network settings to match our actual machines
#. Turn off Quantum, since we made the decision not to use it in order to simplify matters
#. Set up Cinder so that scheduling is handled by the controllers (as normal) but the actual storage happens on the compute node



Lets start with the basic network customization::



    ### GENERAL CONFIG ###
    # This section sets main parameters such as hostnames and IP addresses of different nodes

    # This is the name of the public interface. The public network provides address space for Floating IPs, as well as public IP accessibility to the API endpoints.
    $public_interface = 'eth1'
    $public_br = 'br-ex'
    
    # This is the name of the internal interface. It will be attached to the management network, where data exchange between components of the OpenStack cluster will happen.
    $internal_interface = 'eth0'
    $internal_br = 'br-mgmt'
    
    # This is the name of the private interface. All traffic within OpenStack tenants' networks will go through this interface.
    $private_interface = 'eth2'


In this case, we don't need to make any changes to the interface
settings, because they match what we've already set up. ::

    # Public and Internal VIPs. These virtual addresses are required by HA topology and will be managed by keepalived.
    $internal_virtual_ip = '10.0.0.10'
    # Change this IP to IP routable from your 'public' network,
    # e. g. Internet or your office LAN, in which your public
    # interface resides
    $public_virtual_ip = '10.0.1.10'



The Virtual IPs, however, are not correct for our setup. The host IPs
specified are in use elsewhere in the configuration, and the
$public_virtual_ip needs to be on the public network we've already
specified, so make the changes you see here to sync up with our actual
setup. ::



    # Array containing key/value pairs of controllers and IP addresses for their internal interfaces. Must have an entry for every controller node.
    # Fully Qualified domain names are allowed here along with short hostnames.

    $controller_internal_addresses = {'fuel-controller-01' => '10.0.0.101','fuel-controller-02' => '10.0.0.102','fuel-controller-03' =>'10.0.0.103'}

    # Set hostname of swift_master.
    ...



Next, fix the internal IP addresses for the controllers to match the
addresses they were given earlier.


You'll need to make similar adjustments to the actual node definitions::


    ...
      $primary_controller = false
    }

    $addresses_hash = {
      'fuel-controller-01' => {
        'internal_address' => '10.0.0.101',
        'public_address' => '10.0.1.101',
      },
      'fuel-controller-02' => {
        'internal_address' => '10.0.0.102',
        'public_address' => '10.0.1.102',
      },
      'fuel-controller-03' => {
        'internal_address' => '10.0.0.103',
        'public_address' => '10.0.1.103',
      },
      'fuel-compute-01' => {
        'internal_address' => '10.0.0.110',
        'public_address' => '10.0.1.110',
      },
      'fuel-compute-02' => {
    ...



Again, the internal and public addresses need to match what has
already been set. Don't worry about the fuel-compute-02 and fuel-quantum nodes; were not using them in this setup. (You can delete them
if you want, but its not necessary.)



Finally, you need to correct the gateway and DNS values::



    ...
      'fuel-quantum' => {
            'internal_address' => '10.0.0.108',
            'public_address' => '10.0.204.108',
      },
    }
    $addresses = $addresses_hash
    $default_gateway = '10.0.1.1'
    $dns_nameservers = [$addresses['fuel-pm']['internal_address'],] 
    # Need point to cobbler node IP if you use default use case.

    # Set internal address on which services should listen.
    # We assume that this IP will is equal to one of the haproxy
    ...



The default gateway is the host machine, or more specifically, the
first Hostonly adapter we specified in VirtualBox, which we set to
10.0.1.1.



Finally, make sure that the $dns_nameservers value is looking for
fuel-pm, rather than fuel-cobbler, because we've combined them into one
machine.



Now that the network is configured for the servers, lets look at the
network services.


Enabling Quantum
^^^^^^^^^^^^^^^^^^^^^^^^

In order to deploy OpenStack with Quantum you need to setup an
additional node that will act as a L3 router, or run Quantum out of
one of the existing nodes. In our case we've opted to turn off Quantum::


    ...
    ### GENERAL CONFIG END ###
    ### NETWORK/QUANTUM ###
    # Specify network/quantum specific settings
    
    # Should we use quantum or nova-network(deprecated).
    # Consult OpenStack documentation for differences between them.
    $quantum = false
    $quantum_netnode_on_cnt = false
    
Notice that if we were going to keep Quantum on, the $quantum_netnode_on_cnt lets us specify whether we want Quantum to run
on the controllers. ::


    # Specify network creation criteria:
    # Should puppet automatically create networks?
    $create_networks = true
    # Fixed IP addresses are typically used for communication between VM instances.
    $fixed_range = '10.0.198.128/27'
    # Floating IP addresses are used for communication of VM instances with the outside world (e.g. Internet).
    $floating_range = '10.0.1.128/28'



The Floating IPs will be assigned to OpenStack VMs, and will be the
way in which they will be accessed from the Internet, so the
$floating_range needs to be on the public network. (Notice also that
this range includes 10.0.1.253; that's why we had to move the
$public_virtual_ip to 10.0.1.10.) ::



    # These parameters are passed to the previously specified network manager , e.g. nova-manage network create.
    # Not used in Quantum.
    # Consult openstack docs for corresponding network manager.
    # https://fuel-dev.mirantis.com/docs/0.2/pages/0050-installation-instructions.html#network-setup
    $num_networks = 1
    $network_size = 31
    $vlan_start = 300

    # Quantum
    # Segmentation type for isolating traffic between tenants
    ...



Finally, just as a note, you don't need to change anything here, but
since this example uses nova-network its good to note these values.  You have the option to create multiple VLANs, and the 
IDs for those VLANs run from vlan_start to (vlan_start + num_networks - 1), and are generated
automatically.


Enabling Cinder
^^^^^^^^^^^^^^^

While this example doesnt use Quantum, it does use Cinder, and with
some very specific variations from the default. Specifically, as we
said before, while the Cinder scheduler will continue to run on the
controllers, the actual storage takes place on the compute nodes, on
the /dev/sdb1 partition you created earlier. Cinder will be activated
on any node that contains the specified block devices -- unless
specified otherwise -- so let's look at what all of that means for the
configuration. ::



    ...
    ### CINDER/VOLUME ###
    
    # Should we use cinder or nova-volume(obsolete)
    # Consult openstack docs for differences between them
    $cinder = true
    
    # Should we install cinder on compute nodes?
    $cinder_on_computes = true
    
We want Cinder to be on the compute nodes, so set this value to true. ::



    #Set it to true if your want cinder-volume been installed to the host
    #Otherwise it will install api and scheduler services
    $manage_volumes = true
    
    # Setup network interface, which Cinder uses to export iSCSI targets.
    # This interface defines which IP to use to listen on iscsi port for
    # incoming connections of initiators
    $cinder_iscsi_bind_iface = 'eth3'



Here you have the opportunity to specify which network interface
Cinder uses for its own traffic. As you may recall, we set up a fourth
NIC, and we can specify that here now, rather than using the default
internal interface. ::



    # Below you can add physical volumes to cinder. Please replace values with the actual names of devices.
    # This parameter defines which partitions to aggregate into cinder-volumes or nova-volumes LVM VG
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # USE EXTREME CAUTION WITH THIS SETTING! IF THIS PARAMETER IS DEFINED,
    # IT WILL AGGREGATE THE VOLUMES INTO AN LVM VOLUME GROUP
    # AND ALL THE DATA THAT RESIDES ON THESE VOLUMES WILL BE LOST!
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # Leave this parameter empty if you want to create [cinder|nova]-volumes VG by yourself
    $nv_physical_volume = ['/dev/sdb']
    
    ### CINDER/VOLUME END ###
    ...



We only want to allocate the /dev/sdb value for Cinder, so adjust
$nv_physical_volume accordingly. Note, however, that this is a global
value; it will apply to all servers, including the controllers --
unless we specify otherwise, which we will in a moment.



**Be careful** to not add block devices to the list which contain useful
data (e.g. block devices on which your OS resides), as they will be
destroyed after you allocate them for Cinder.



Now lets look at the other storage-based service: Swift.


Enabling Swift
^^^^^^^^^^^^^^

There aren't many changes that you will need to make to the default
configuration in order to enable Swift to work properly in Swift
Compact mode, but you will need to adjust for the fact that we are
running Swift on physical partitions::


    ...
    ### GLANCE and SWIFT ###
    
    # Which backend to use for glance
    # Supported backends are "swift" and "file"
    $glance_backend = 'swift'
    
    # Use loopback device for swift:
    # set 'loopback' or false
    # This parameter controls where swift partitions are located:
    # on physical partitions or inside loopback devices.
    $swift_loopback = false
    
The default value is loopback, which tells Swift to use a loopback storage device, which is basically a file that acts like a drive, rather than an actual physical drive. ::


    # Which IP address to bind swift components to: e.g., which IP swift-proxy should listen on
    $swift_local_net_ip = $internal_address
    
    # IP node of controller used during swift installation
    # and put into swift configs
    $controller_node_public = $internal_virtual_ip
    
    # Set hostname of swift_master.
    # It tells on which swift proxy node to build
    # *ring.gz files. Other swift proxies/storages
    # will rsync them.
    # Short hostnames allowed only. No FQDNs.
    
    # Hash of proxies hostname|fqdn => ip mappings.
    # This is used by controller_ha.pp manifests for haproxy setup
    # of swift_proxy backends
    $swift_proxies = $controller_internal_addresses
    
    ### Glance and swift END ###
    ...



Now we just need to make sure that all of our nodes get the proper
values.


Defining the node configurations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Now that we've set all of the global values, its time to make sure that
the actual node definitions are correct. For example, by default all
nodes will enable Cinder on /dev/sdb, but we don't want that for the
controllers, so set nv_physical_volume to null, and manage_volumes to false. ::



    ...
    class compact_controller (
        $quantum_network_node = false
    ) {
      class { 'openstack::controller_ha':
        controller_public_addresses => $controller_public_addresses,
        controller_internal_addresses => $controller_internal_addresses,
        internal_address => $internal_address,
    ...
        tenant_network_type => $tenant_network_type,
        segment_range => $segment_range,
        cinder => $cinder,
        cinder_iscsi_bind_iface => $cinder_iscsi_bind_iface,
        manage_volumes => false,
        galera_nodes => $controller_hostnames,
        nv_physical_volume => null,
        use_syslog => $use_syslog,
        nova_rate_limits => $nova_rate_limits,
        cinder_rate_limits => $cinder_rate_limits,
        horizon_use_ssl => $horizon_use_ssl,
      }
      class { 'swift::keystone::auth':
        password => $swift_user_password,
        public_address => $public_virtual_ip,
        internal_address => $internal_virtual_ip,
        admin_address => $internal_virtual_ip,
      }
    }
    ...



Fortunately, Fuel includes a class for the controllers, so you don't
have to make these changes for each individual controller. As you can
see, the controllers generally use the global values, but in this case
you're telling the controllers not to manage_volumes, and not to use
/dev/sdb for Cinder.



If you look down a little further, this class then goes on to help
specify the individual controllers::


    ...
    # Definition of the first OpenStack controller.
    node /fuel-controller-01/ {
      class {'::node_netconfig':
            mgmt_ipaddr => $::internal_address,
            mgmt_netmask => $::internal_netmask,
            public_ipaddr => $::public_address,
            public_netmask => $::public_netmask,
            stage => 'netconfig',
      }
      class {'nagios':
            proj_name => $proj_name,
            services => [
                'host-alive','nova-novncproxy','keystone', 'nova-scheduler',
                'nova-consoleauth', 'nova-cert', 'haproxy', 'nova-api', 'glance-api',
                'glance-registry','horizon', 'rabbitmq', 'mysql', 'swift-proxy',
                'swift-account', 'swift-container', 'swift-object',
            ],
            whitelist => ['127.0.0.1', $nagios_master],
            hostgroup => 'controller',
      }

      class { compact_controller: }
      $swift_zone = 1

      class { 'openstack::swift::storage_node':
        storage_type => $swift_loopback,
        swift_zone => $swift_zone,
        swift_local_net_ip => $internal_address,
      }

      class { 'openstack::swift::proxy':
        swift_user_password     => $swift_user_password,
        swift_proxies => $swift_proxies,
        primary_proxy => $primary_proxy,
        controller_node_address => $internal_virtual_ip,
        swift_local_net_ip => $internal_address,
      }
    }
    ...



Notice also that each controller has the swift_zone specified, so each
of the three controllers can represent each of the three Swift zones.

<<<<<<< HEAD
=======
In ``openstack/examples/site_openstack_full.pp`` example, the following nodes are specified:
>>>>>>> 5f32c0d... Rename and sync manifests


<<<<<<< HEAD
=======
In ``openstack/examples/site_openstack_compact.pp`` example, the role of swift-storage and swift-proxy combined with controllers.
>>>>>>> 5f32c0d... Rename and sync manifests

One final fix
^^^^^^^^^^^^^

Although the $controller_public_addresses value is deprecated, it must
be specified correctly or your cluster will not function properly. You
can find this value at the very bottom of the site.pp file::


    ...
    # This configuration option is deprecated and will be removed in future releases. It's currently kept for backward compatibility.
    $controller_public_addresses = {'fuel-controller-01' => '10.0.1.101','fuel-controller-02' => '10.0.1.102','fuel-controller-03' =>'10.0.1.103'}



Now you're ready to perform the actual installation.


Installing OpenStack on the nodes using Puppet
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Now that you've set all of your configurations, all that's left to stand
up your OpenStack cluster is to run Puppet on each of your nodes; the
Puppet Master knows what to do for each of them.



Start by logging in to fuel-controller-01 and running the Puppet
agent. One optional step would be to use the script command to log all
of your output so you can check for errors if necessary::



    script agent-01.log
    puppet agent --test



You will to see a great number of messages scroll by, and the
installation will take a significan't amount of time. When the process
has completed, press CTRL-D to stop logging and grep for errors::



    grep err: agent-01.log



If you find any errors relating to other nodes, ignore them for now.



Now you can run the same installation procedure on fuel-controller-01
and fuel-controller-02, as well as fuel-compute-01.



Note that the controllers must be installed sequentially due to the
nature of assembling a MySQL cluster based on Galera, which means that
one must complete its installation before the next begins, but that
compute nodes can be installed concurrently once the controllers are
in place.



In some cases, you may find errors related to resources that are not
yet available when the installation takes place. To solve that
problem, simply re-run the puppet agent on the affected node, and
again grep for error messages.



When you see no errors on any of your nodes, your OpenStack cluster is
ready to go.

Configuring OpenStack to use syslog
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* If you want to use syslog server, you need to do the following steps:

Adjust the corresponding variables in "if $use_syslog" clause::

    $use_syslog = true
        if $use_syslog {
            class { "::rsyslog::client": 
                log_local => true,
                log_auth_local => true,
                server => '127.0.0.1',
                port => '514'
            }
    }

For remote logging:

            server => <syslog server hostname or ip>

            port => <syslog server port>

For local logging:

            set log_local and log_auth_local to true
   

Setting the mirror type
^^^^^^^^^^^^^^^^^^^^^^^


To tell Fuel to download packages from external repos provided by Mirantis and your distribution vendors, set the $mirror_type variable to "external"::

    ...
    # If you want to set up a local repository, you will need to manually adjust mirantis_repos.pp,
    # though it is NOT recommended.
    $mirror_type = 'external'
    $enable_test_repo = false
    ...

Future versions of Fuel will enable you to use your own internal repositories.
 
Configuring Rate-Limits
^^^^^^^^^^^^^^^^^^^^^^^

Openstack has predefined limits on different HTTP queries for nova-compute and cinder services. Some
times (e.g. for big clouds or test scenarios) these limits are too strict. (See http://docs.openstac
k.org/folsom/openstack-compute/admin/content/configuring-compute-API.html) In this case you can chan
ge them to appropriate values.

There are two hashes describing these limits: $nova_rate_limits and $cinder_rate_limits. ::

    $nova_rate_limits = { 'POST' => '10',
    'POST_SERVERS' => '50',
    'PUT' => 10, 'GET' => 3,
    'DELETE' => 100 }

    $cinder_rate_limits = { 'POST' => '10',
    'POST_SERVERS' => '50',
    'PUT' => 10, 'GET' => 3,
    'DELETE' => 100 }



Installing Nagios Monitoring using Puppet
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Installing nagios NRPE on compute or controller node: ::

  class {'nagios':
  proj_name       => 'test',
  services        => ['nova-compute','nova-network','libvirt'],
  whitelist       => ['127.0.0.1','10.0.97.5'],
  hostgroup       => 'compute',
  }

where ``proj_name`` is an environment for nagios commands and directory

in this case:
        "``/etc/nagios/test/``"

* ``services``  - all services which nagios will monitor
* ``whitelist`` - array of IP addreses which NRPE trusts
* ``hostgroup`` - group to be used in nagios master (do not forget create it in nagios master)

Installing nagios Master on any convenient node: ::

  class {'nagios::master':
    proj_name       => 'test',
    templatehost    => {'name' => 'default-host','check_interval' => '10'},
    templateservice => {'name' => 'default-service' ,'check_interval'=>'10'},
    hostgroups      => ['compute','controller'],
    contactgroups   => {'group' => 'admins', 'alias' => 'Admins'}, 
    contacts        => {'user' => 'hotkey', 'alias' => 'Dennis Hoppe',
                 'email' => 'nagios@%{domain}',
                 'group' => 'admins'},
  }

where ``proj_name`` is an environment for nagios services and directory

in this case:
        "``/etc/nagios3/test/``"

*  ``templatehost`` - group of checks and intervals parameters for hosts (as Hash)
*  ``templateservice`` - group of checks and intervals parameters for services  (as Hash)
*  ``hostgroups`` - just add all groups which were on NRPE nodes (as Array)
*  ``contactgroups`` - group of contacts {as Hash}
*  ``contacts`` - create contacts for send error reports to {as Hash}


Examples of OpenStack installation sequences
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**First, please see the link below for details about different deployment scenarios.**

     :ref:`Swift-and-object-storage-notes`

  **Note:** No changes to ``site.pp`` necessary between installation phases except the *Controller + Compute on the same node* case. You simply run the same puppet scenario in several passes over the already installed node. Every deployment pass Puppet collects and adds necessary absent information to OpenStack configuration, stores it to PuppedDB and applies necessary changes. But please use appropriate ``site.pp`` from OpenStack Examples as base file for your OpenStack deployment.

  **Note:** *Sequentially run* means you don't start the next node deployment until previous one is finished.

  **Example1:** **Full OpenStack deployment with standalone storage nodes**

    * Create necessary volumes on storage nodes as described in	 :ref:`create-the-XFS-partition`
    * Sequentially run deployment pass on controller nodes (``fuel-controller-01 ... fuel-controller-xx``).
    * Run additional deployment pass on Controller 1 only (``fuel-controller-01``) to finalize Galera cluster configuration.
    * Run deployment pass on Quantum node (``fuel-quantum``) to install Quantum router.
    * Run deployment pass on every compute node (``fuel-compute-01 ... fuel-compute-xx``) - unlike controllers these nodes may be deployed in parallel.
    * Sequentially run deployment pass on every storage node (``fuel-sowift-01`` ... ``fuel-swift-xx``) node. By default these nodes named as ``fuel-swift-xx``. Errors in Swift storage like */Stage[main]/Swift::Storage::Container/Ring_container_device[<device address>]: Could not evaluate: Device not found check device on <device address>* are expected on Storage nodes during the deployment passes until the very final pass.
    * In case loopback devices are used on storage nodes (``$swift_loopback = 'loopback'`` in ``site.pp``) - run deployment pass on every storage (``fuel-swift-01`` ... ``fuel-swift-xx``) node one more time. Skip this step in case loopback is off (``$swift_loopback = false`` in ``site.pp``). Again, ignore errors in *Swift::Storage::Container* during this deployment pass.
    * Run deployment pass on every SwiftProxy node (``fuel-swiftproxy-01 ... fuel-swiftproxy-02``). Node names are set by ``$swift_proxies`` variable in ``site.pp``. There are 2 Swift Proxies by default.
    * Repeat deployment pass on every storage (``fuel-swift-01`` ... ``fuel-swift-xx``) node. No Swift storage errors should appear during this deployment pass!

  **Example2:** **Compact OpenStack deployment with storage and swift-proxy combined with nova-controller on the same nodes**

    * Create necessary volumes on controller nodes as described in	 :ref:`create-the-XFS-partition`
    * Sequentially run deployment pass on controller nodes (``fuel-controller-01 ... fuel-controller-xx``). Errors in Swift storage like */Stage[main]/Swift::Storage::Container/Ring_container_device[<device address>]: Could not evaluate: Device not found check device on <device address>* are expected during the deployment passes until the very final pass.
    * Run deployment pass on Quantum node (``fuel-quantum``) to install Quantum router.
    * Run deployment pass on every compute node (``fuel-compute-01 ... fuel-compute-xx``) - unlike controllers these nodes may be deployed in parallel.
    * Sequentially run one more deployment pass on every controller (``fuel-controller-01 ... fuel-controller-xx``) node. Again, ignore errors in *Swift::Storage::Container* during this deployment pass.
    * Run additional deployment pass *only* on controller, which holds on the SwiftProxy service. By default it is ``fuel-controller-01``. And again, ignore errors in *Swift::Storage::Container* during this deployment pass.
    * Sequentially run one more deployment pass on every controller (``fuel-controller-01 ... fuel-controller-xx``) node to finalize storage configuration. No Swift storage errors should appear during this deployment pass!

  **Example3:** **OpenStack HA installation without Swift**

    * Sequentially run deployment pass on controller nodes (``fuel-controller-01 ... fuel-controller-xx``). No errors should appear during this deployment pass.
    * Run additional deployment pass on Controller 1 only (``fuel-controller-01``) to finalize Galera cluster configuration.
    * Run deployment pass on Quantum node (``fuel-quantum``) to install Quantum router.
    * Run deployment pass on every compute node (``fuel-compute-01 ... fuel-compute-xx``) - unlike controllers these nodes may be deployed in parallel.

  **Example4:** **The most simple OpenStack installation Controller + Compute on the same node**

    * Set ``node /fuel-controller-[\d+]/`` variable in ``site.pp`` to match with node name you are going to deploy OpenStack. Set ``node /fuel-compute-[\d+]/`` variable to **mismatch** with node name. Run deployment pass on this node. No errors should appear during this deployment pass.
    * Set ``node /fuel-compute-[\d+]/`` variable in ``site.pp`` to match with node name you are going to deploy OpenStack. Set ``node /fuel-controller-[\d+]/`` variable to **mismatch** with node name. Run deployment pass on this node. No errors should appear during this deployment pass.
