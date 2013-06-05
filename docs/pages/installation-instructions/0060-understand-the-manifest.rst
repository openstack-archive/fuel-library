
Understanding the Puppet manifest
---------------------------------

At this point you have functioning servers that are ready to have
OpenStack installed. If you're using VirtualBox, save the current state
of every virtual machine by taking a snapshot using ``File->Take Snapshot``. This
way you can go back to this point and try again if necessary.


The next step will be to go through the ``/etc/puppet/manifests/site.pp`` file and make any
necessary customizations.  If you have run ``openstack_system``, there shouldn't be anything to change (with one small exception) but if you are installing Fuel manually, you will need to make these changes yourself.  

In either case, it's always good to understand what your system is doing. 


Let's start with the basic network customization::



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
    $public_virtual_ip = '192.168.0.10'



Make sure the virtual IPs you see here mesh with your actual setup; they should be IPs that are routeable, but not within the range of the DHCP scope.   These are the IPs through which your services will be accessed.  

The next section sets up the servers themselves.  If you are setting up Fuel manually, make sure to add each server with the appropriate IP addresses; if you ran ``openstack_system``, the values will be overridden by the next section, and you can ignore this array. ::

  $nodes_harr = [
    {
      'name' => 'fuel-pm',
      'role' => 'cobbler',
      'internal_address' => '10.0.0.100',
      'public_address'   => '192.168.0.100',
      'mountpoints'=> "1 1\n2 1",
      'storage_local_net_ip' => '10.0.0.100',
    },
    {
      'name' => 'fuel-controller-01',
      'role' => 'primary-controller',
      'internal_address' => '10.0.0.101',
      'public_address'   => '192.168.0.101',
      'mountpoints'=> "1 1\n2 1",
      'storage_local_net_ip' => '10.0.0.101',
    },
    {
      'name' => 'fuel-controller-02',
      'role' => 'controller',
      'internal_address' => '10.0.0.102',
      'public_address'   => '192.168.0.102',
      'mountpoints'=> "1 1\n2 1",
      'storage_local_net_ip' => '10.0.0.102',
    },
    {
      'name' => 'fuel-controller-03',
      'role' => 'controller',
      'internal_address' => '10.0.0.105',
      'public_address'   => '192.168.0.105',
      'mountpoints'=> "1 1\n2 1",
      'storage_local_net_ip' => '10.0.0.105',
    },
    {
      'name' => 'fuel-compute-01',
      'role' => 'compute',
      'internal_address' => '10.0.0.106',
      'public_address'   => '192.168.0.106',
      'mountpoints'=> "1 1\n2 1",
      'storage_local_net_ip' => '10.0.0.106',
    }
  ]

Because this section comes from a template, it will likely include a number of servers you're not using; feel free to leave them or take them out. 

Next the ``site.pp`` file lists all of the nodes and roles you defined in the ``config.yaml`` file::

  $nodes = [{'public_address' => '192.168.0.101','name' => 'fuel-controller-01','role' => 
             'primary-controller','internal_address' => '10.0.0.101', 
             'storage_local_net_ip' => '10.0.0.101', 'mountpoints' => '1 2\n2 1',
             'swift-zone' => 1 },
            {'public_address' => '192.168.0.102','name' => 'fuel-controller-02','role' => 
             'controller','internal_address' => '10.0.0.102', 
             'storage_local_net_ip' => '10.0.0.102', 'mountpoints' => '1 2\n2 1',
             'swift-zone' => 2},
            {'public_address' => '192.168.0.103','name' => 'fuel-controller-03','role' => 
             'storage','internal_address' => '10.0.0.103', 
             'storage_local_net_ip' => '10.0.0.103', 'mountpoints' => '1 2\n2 1',
             'swift-zone' => 3},
            {'public_address' => '192.168.0.110','name' => 'fuel-compute-01','role' => 
             'compute','internal_address' => '10.0.0.110'}]

Possible roles include ‘compute’,  ‘controller’, ‘primary-controller’, ‘storage’, ‘swift-proxy’, ‘quantum’, ‘master’, and ‘cobbler’. Check the IP addresses for each node and make sure that they mesh with what's in this array.

The file also specifies the default gateway to be the fuel-pm machine::

  $default_gateway = '192.168.0.1'

Next ``site.pp`` defines DNS servers and provides netmasks::

  # Specify nameservers here.
  # Need points to cobbler node IP, or to special prepared nameservers if you known what you do.
  $dns_nameservers = ['10.0.0.100','8.8.8.8']

  # Specify netmasks for internal and external networks.
  $internal_netmask = '255.255.255.0'
  $public_netmask = '255.255.255.0'
  ...
  #Set this to anything other than pacemaker if you do not want Quantum HA
  #Also, if you do not want Quantum HA, you MUST enable $quantum_network_node
  #on the ONLY controller
  $ha_provider = 'pacemaker'
  $use_unicast_corosync = false

Next specify the main controller as the Nagios master. ::

  # Set nagios master fqdn
  $nagios_master = 'fuel-controller-01.localdomain'
  ## proj_name  name of environment nagios configuration
  $proj_name            = 'test'

Here again we have a parameter that looks ahead to things to come; OpenStack supports monitoring via Nagios.  In this section, you can choose the Nagios master server as well as setting a project name. ::

  #Specify if your installation contains multiple Nova controllers. Defaults to true as it is the most common scenario.
  $multi_host              = true

A single host cloud isn't especially useful, but if you really want to, you can specify that here.

Finally, you can define the various usernames and passwords for OpenStack services. ::

  # Specify different DB credentials for various services
  $mysql_root_password     = 'nova'
  $admin_email             = 'openstack@openstack.org'
  $admin_password          = 'nova'

  $keystone_db_password    = 'nova'
  $keystone_admin_token    = 'nova'

  $glance_db_password      = 'nova'
  $glance_user_password    = 'nova'

  $nova_db_password        = 'nova'
  $nova_user_password      = 'nova'

  $rabbit_password         = 'nova'
  $rabbit_user             = 'nova'

  $swift_user_password     = 'swift_pass'
  $swift_shared_secret     = 'changeme'

  $quantum_user_password   = 'quantum_pass'
  $quantum_db_password     = 'quantum_pass'
  $quantum_db_user         = 'quantum'
  $quantum_db_dbname       = 'quantum'

  # End DB credentials section

Now that the network is configured for the servers, let's look at the
various OpenStack services.


Enabling Quantum
^^^^^^^^^^^^^^^^

In order to deploy OpenStack with Quantum you need to set up an
additional node that will act as an L3 router, or run Quantum out of
one of the existing nodes. ::

  ### NETWORK/QUANTUM ###
  # Specify network/quantum specific settings

  # Should we use quantum or nova-network(deprecated).
  # Consult OpenStack documentation for differences between them.
  $quantum = true
  $quantum_netnode_on_cnt  = true

In this case, we're using a "compact" architecture, so we want to place Quantum on the controllers::

  # Specify network creation criteria:
  # Should puppet automatically create networks?
  $create_networks = true

  # Fixed IP addresses are typically used for communication between VM instances.
  $fixed_range = '172.16.0.0/16'

  # Floating IP addresses are used for communication of VM instances with the outside world (e.g. Internet).
  $floating_range = '192.168.0.0/24'

OpenStack uses two ranges of IP addresses for virtual machines: fixed IPs, which are used for communication between VMs, and thus are part of the private network, and floating IPs, which are assigned to VMs for the purpose of communicating to and from the Internet. ::

  # These parameters are passed to the previously specified network manager , e.g. nova-manage network create.
  # Not used in Quantum.
  $num_networks    = 1
  $network_size    = 31
  $vlan_start      = 300

These values don't actually relate to Quantum; they are used by nova-network.  IDs for the VLANs OpenStack will create for tenants run from ``vlan_start`` to (``vlan_start + num_networks - 1``), and are generated automatically. ::

  # Quantum

  # Segmentation type for isolating traffic between tenants
  # Consult Openstack Quantum docs 
  $tenant_network_type     = 'gre'

  # Which IP address will be used for creating GRE tunnels.
  $quantum_gre_bind_addr = $internal_address

If you are installing Quantum in non-HA mode, you will need to specify which single controller controls Quantum. :: 

  # If $external_ipinfo option is not defined, the addresses will be allocated automatically from $floating_range:
  # the first address will be defined as an external default router,
  # the second address will be attached to an uplink bridge interface,
  # the remaining addresses will be utilized for the floating IP address pool.
  $external_ipinfo = {
     'pool_start' => '192.168.0.115',
	 'public_net_router' => '192.168.0.1', 
	 'pool_end' => '192.168.0.126',
	 'ext_bridge' => '0.0.0.0'
  }

  # Quantum segmentation range.
  # For VLAN networks: valid VLAN VIDs can be 1 through 4094.
  # For GRE networks: Valid tunnel IDs can be any 32-bit unsigned integer.
  $segment_range = '900:999'

  # Set up OpenStack network manager. It is used ONLY in nova-network.
  # Consult Openstack nova-network docs for possible values.
  $network_manager = 'nova.network.manager.FlatDHCPManager'
  
  # Assign floating IPs to VMs on startup automatically?
  $auto_assign_floating_ip = false

  # Database connection for Quantum configuration (quantum.conf)
  $quantum_sql_connection  = "mysql://${quantum_db_user}:${quantum_db_password}@${$internal_virtual_ip}/{quantum_db_dbname}"

  if $quantum {
    $public_int   = $public_br
    $internal_int = $internal_br
  } else {
    $public_int   = $public_interface
    $internal_int = $internal_interface
  }

If the system is set up to use Quantum, the public and internal interfaces are set to use the appropriate bridges, rather than the defined interfaces.

The remaining configuration is used to define classes that will be added to each Quantum node::

  #Network configuration
  stage {'netconfig':
        before  => Stage['main'],
  }
  class {'l23network': use_ovs => $quantum, stage=> 'netconfig'}
  class node_netconfig (
    $mgmt_ipaddr,
    $mgmt_netmask  = '255.255.255.0',
    $public_ipaddr = undef,
    $public_netmask= '255.255.255.0',
    $save_default_gateway=true,
    $quantum = $quantum,
  ) {
    if $quantum {
      l23network::l3::create_br_iface {'mgmt':
        interface => $internal_interface, # !!! NO $internal_int /sv !!!
        bridge    => $internal_br,
        ipaddr    => $mgmt_ipaddr,
        netmask   => $mgmt_netmask,
        dns_nameservers      => $dns_nameservers,
        save_default_gateway => $save_default_gateway,
      } ->
      l23network::l3::create_br_iface {'ex':
        interface => $public_interface, # !! NO $public_int /sv !!!
        bridge    => $public_br,
        ipaddr    => $public_ipaddr,
        netmask   => $public_netmask,
        gateway   => $default_gateway,
      }
    } else {
      # nova-network mode
      l23network::l3::ifconfig {$public_int:
        ipaddr  => $public_ipaddr,
        netmask => $public_netmask,
        gateway => $default_gateway,
      }
      l23network::l3::ifconfig {$internal_int:
        ipaddr  => $mgmt_ipaddr,
        netmask => $mgmt_netmask,
        dns_nameservers      => $dns_nameservers,
      }
    }
    l23network::l3::ifconfig {$private_interface: ipaddr=>'none' }
  }
  ### NETWORK/QUANTUM END ###

All of this assumes, of course, that you're using Quantum; if you're using nova-network instead, only those values apply.

Defining the current cluster
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Fuel enables you to control multiple deployments simultaneously by setting an individual deployment ID::

  # This parameter specifies the the identifier of the current cluster. This is needed in case of multiple environments.
  # installation. Each cluster requires a unique integer value. 
  # Valid identifier range is 0 to 254
  $deployment_id = '79'

Enabling Cinder
^^^^^^^^^^^^^^^

This example also uses Cinder, and with
some very specific variations from the default. Specifically, as we
said before, while the Cinder scheduler will continue to run on the
controllers, the actual storage takes place on the compute nodes, on
the ``/dev/sdb1`` partition you created earlier. Cinder will be activated
on any node that contains the specified block devices -- unless
specified otherwise -- so let's look at what all of that means for the
configuration. ::


   # Choose which nodes to install cinder onto
   # 'compute'            -> compute nodes will run cinder
   # 'controller'         -> controller nodes will run cinder
   # 'storage'            -> storage nodes will run cinder
   # 'fuel-controller-XX' -> specify particular host(s) by hostname
   # 'XXX.XXX.XXX.XXX'    -> specify particular host(s) by IP address
   # 'all'                -> compute, controller, and storage nodes will run cinder (excluding swift and proxy nodes)
   $cinder_nodes          = ['controller']
    
We want Cinder to be on the controller nodes, so set this value to ``['controller']``. ::



    #Set it to true if your want cinder-volume been installed to the host
    #Otherwise it will install api and scheduler services
    $manage_volumes = true
    
    # Setup network interface, which Cinder uses to export iSCSI targets.
    $cinder_iscsi_bind_addr = $internal_address



Here you have the opportunity to specify which network interface
Cinder uses for its own traffic. For example, you could set up a fourth NIC at ``eth3`` 
and specify that rather than ``$internal_int``.  ::



    # Below you can add physical volumes to cinder. Please replace values with the actual names of devices.
    # This parameter defines which partitions to aggregate into cinder-volumes or nova-volumes LVM VG
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # USE EXTREME CAUTION WITH THIS SETTING! IF THIS PARAMETER IS DEFINED,
    # IT WILL AGGREGATE THE VOLUMES INTO AN LVM VOLUME GROUP
    # AND ALL THE DATA THAT RESIDES ON THESE VOLUMES WILL BE LOST!
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # Leave this parameter empty if you want to create [cinder|nova]-volumes VG by yourself
    $nv_physical_volume = ['/dev/sdb']

    #Evaluate cinder node selection
    if ($cinder) {
      if (member($cinder_nodes,'all')) {
         $is_cinder_node = true
      } elsif (member($cinder_nodes,$::hostname)) {
         $is_cinder_node = true
      } elsif (member($cinder_nodes,$internal_address)) {
         $is_cinder_node = true
      } elsif ($node[0]['role'] =~ /controller/)) {
         $is_cinder_node = member($cinder_nodes, 'controller')
      } else {
         $is_cinder_node = member($cinder_nodes, $node[0]['role'])
      }
    } else {
      $is_cinder_node = false
    }
    
    ### CINDER/VOLUME END ###


We only want to allocate the ``/dev/sdb`` value for Cinder, so adjust
``$nv_physical_volume`` accordingly. Note, however, that this is a global
value; it will apply to all servers, including the controllers --
unless we specify otherwise, which we will in a moment.



**Be careful** to not add block devices to the list which contain useful
data (e.g. block devices on which your OS resides), as they will be
destroyed after you allocate them for Cinder.



Now lets look at the other storage-based service: Swift.


Enabling Glance and Swift
^^^^^^^^^^^^^^^^^^^^^^^^^

There aren't many changes that you will need to make to the default
configuration in order to enable Swift to work properly in Swift
Compact mode, but you will need to adjust if you want to run Swift on physical partitions ::


    ...
    ### GLANCE and SWIFT ###
    
    # Which backend to use for glance
    # Supported backends are "swift" and "file"
    $glance_backend = 'swift'
    
    # Use loopback device for swift:
    # set 'loopback' or false
    # This parameter controls where swift partitions are located:
    # on physical partitions or inside loopback devices.
    $swift_loopback = loopback
    
The default value is ``loopback``, which tells Swift to use a loopback storage device, which is basically a file that acts like a drive, rather than an actual physical drive.  You can also set this value to ``false``, which tells OpenStack to use a physical file instead. ::


    # Which IP address to bind swift components to: e.g., which IP swift-proxy should listen on
    $swift_local_net_ip = $internal_address
    
    # IP node of controller used during swift installation
    # and put into swift configs
    $controller_node_public = $internal_virtual_ip

    # Hash of proxies hostname|fqdn => ip mappings.
    # This is used by controller_ha.pp manifests for haproxy setup
    # of swift_proxy backends
    $swift_proxies = $controller_internal_addresses

Next, you're specifying the ``swift-master``::

  # Set hostname of swift_master.
  # It tells on which swift proxy node to build
  # *ring.gz files. Other swift proxies/storages
  # will rsync them.
  if $node[0]['role'] == 'primary-controller' {
    $primary_proxy = true
  } else {
    $primary_proxy = false
  }
  if $node[0]['role'] == 'primary-controller' {
    $primary_controller = true
  } else {
    $primary_controller = false
  }
  $master_swift_proxy_nodes = filter_nodes($nodes,'role','primary-controller')
  $master_swift_proxy_ip = $master_swift_proxy_nodes[0]['internal_address']

In this case, there's no separate ``fuel-swiftproxy-01``, so the master controller will be the primary Swift controller.

Configuring OpenStack to use syslog
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To use the syslog server, adjust the corresponding variables in the ``if $use_syslog`` clause::

    $use_syslog = true
    if $use_syslog {
        class { "::rsyslog::client": 
            log_local => true,
            log_auth_local => true,
            server => '127.0.0.1',
            port => '514'
        }
    }


For remote logging, use the IP or hostname of the server for the ``server`` value and set the ``port`` appropriately.  For local logging, ``set log_local`` and ``log_auth_local`` to ``true``.
   

Setting the version and mirror type
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You can customize the various versions of OpenStack's components, though it's typical to use the latest versions::

   ### Syslog END ###
   case $::osfamily {
       "Debian":  {
          $rabbitmq_version_string = '2.8.7-1'
       }
       "RedHat": {
          $rabbitmq_version_string = '2.8.7-2.el6'
       }
   }
   # OpenStack packages and customized component versions to be installed. 
   # Use 'latest' to get the most recent ones or specify exact version if you need to install custom version.
   $openstack_version = {
     'keystone'         => 'latest',
     'glance'           => 'latest',
     'horizon'          => 'latest',
     'nova'             => 'latest',
     'novncproxy'       => 'latest',
     'cinder'           => 'latest',
     'rabbitmq_version' => $rabbitmq_version_string,
   }

To tell Fuel to download packages from external repos provided by Mirantis and your distribution vendors, make sure the ``$mirror_type`` variable is set to ``default``::

    # If you want to set up a local repository, you will need to manually adjust mirantis_repos.pp,
    # though it is NOT recommended.
    $mirror_type = 'default'
    $enable_test_repo = false
    $repo_proxy = 'http://10.0.0.100:3128'

Once again, the ``$mirror_type`` **must** be set to ``default``.  If you set it correctly in ``config.yaml`` and ran ``openstack_system`` this will already be taken care of.  Otherwise, **make sure** to set this value yourself.

Future versions of Fuel will enable you to use your own internal repositories.

Setting verbosity
^^^^^^^^^^^^^^^^^ 

You also have the option to determine how much information OpenStack provides when performing configuration::

  # This parameter specifies the verbosity level of log messages
  # in openstack components config. Currently, it disables or enables debugging.
  $verbose = true


Configuring Rate-Limits
^^^^^^^^^^^^^^^^^^^^^^^

Openstack has predefined limits on different HTTP queries for nova-compute and cinder services. Sometimes (e.g. for big clouds or test scenarios) these limits are too strict. (See http://docs.openstack.org/folsom/openstack-compute/admin/content/configuring-compute-API.html.) In this case you can change them to more appropriate values.

There are two hashes describing these limits: ``$nova_rate_limits`` and ``$cinder_rate_limits``. ::

    #Rate Limits for cinder and Nova
    #Cinder and Nova can rate-limit your requests to API services.
    #These limits can be reduced for your installation or usage scenario.
    #Change the following variables if you want. They are measured in requests per minute.
    $nova_rate_limits = {
      'POST' => 1000,
      'POST_SERVERS' => 1000,
      'PUT' => 1000, 'GET' => 1000,
      'DELETE' => 1000 
    }
    $cinder_rate_limits = {
      'POST' => 1000,
      'POST_SERVERS' => 1000,
      'PUT' => 1000, 'GET' => 1000,
      'DELETE' => 1000 
    }
    ...


Enabling Horizon HTTPS/SSL mode
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Using the ``$horizon_use_ssl`` variable, you have the option to decide whether the OpenStack dashboard (Horizon) uses HTTP or HTTPS::

    ...
    #  'custom': require fileserver static mount point [ssl_certs] and hostname based certificate existence
    $horizon_use_ssl = false

This variable accepts the following values:

  * ``false``:  In this mode, the dashboard uses HTTP with no encryption.
  * ``default``:  In this mode, the dashboard uses keys supplied with the standard Apache SSL module package.
  * ``exist``:  In this case, the dashboard assumes that the domain name-based certificate, or keys, are provisioned in advance.  This can be a certificate signed by any authorized provider, such as Symantec/Verisign, Comodo, GoDaddy, and so on.  The system looks for the keys in these locations:

    for Debian/Ubuntu:
      * public  ``/etc/ssl/certs/domain-name.pem``
      * private ``/etc/ssl/private/domain-name.key``
    for Centos/RedHat:
      * public  ``/etc/pki/tls/certs/domain-name.crt``
      * private ``/etc/pki/tls/private/domain-name.key``

  * ``custom``:  This mode requires a static mount point on the fileserver for ``[ssl_certs]`` and certificate pre-existence.  To enable this mode, configure the puppet fileserver by editing ``/etc/puppet/fileserver.conf`` to add::

      [ssl_certs]
        path /etc/puppet/templates/ssl
        allow *

    From there, create the appropriate directory::

      mkdir -p /etc/puppet/templates/ssl

    Add the certificates to this directory.  (Reload the puppetmaster service for these changes to take effect.)

Now we just need to make sure that all of our nodes get the proper
values.


Defining the node configurations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Now that we've set all of the global values, its time to make sure that
the actual node definitions are correct. For example, by default all
nodes will enable Cinder on ``/dev/sdb``.  If you didn't want that for all
controllers, you could set ``nv_physical_volume`` to ``null`` for a specific node or nodes. ::


    ...
    class compact_controller (
      $quantum_network_node = $quantum_netnode_on_cnt
    ) {
      class { 'openstack::controller_ha':
        controller_public_addresses   => $controller_public_addresses,
        controller_internal_addresses => $controller_internal_addresses,
        internal_address        => $internal_address,
        public_interface        => $public_int,
        internal_interface      => $internal_int,
     ...
        use_unicast_corosync    => $use_unicast_corosync,
        ha_provider             => $ha_provider
      }
      class { 'swift::keystone::auth':
        password         => $swift_user_password,
        public_address   => $public_virtual_ip,
        internal_address => $internal_virtual_ip,
        admin_address    => $internal_virtual_ip,
      }
    }
    ...



Fortunately, as you can see here, Fuel includes a class for the controllers, so you don't
have to make global changes for each individual controller.  If you look down a little further, this class then goes on to help specify the individual controllers and compute nodes::


    ...
	node /fuel-controller-[\d+]/ {
	  include stdlib
	  class { 'operatingsystem::checksupported':
	      stage => 'setup'
	  }

	  class {'::node_netconfig':
	      mgmt_ipaddr    => $::internal_address,
	      mgmt_netmask   => $::internal_netmask,
	      public_ipaddr  => $::public_address,
	      public_netmask => $::public_netmask,
	      stage          => 'netconfig',
	  }

	  class {'nagios':
	    proj_name       => $proj_name,
	    services        => [
	      'host-alive','nova-novncproxy','keystone', 'nova-scheduler',
	      'nova-consoleauth', 'nova-cert', 'haproxy', 'nova-api', 'glance-api',
	      'glance-registry','horizon', 'rabbitmq', 'mysql', 'swift-proxy',
	      'swift-account', 'swift-container', 'swift-object',
	    ],
	    whitelist       => ['127.0.0.1', $nagios_master],
	    hostgroup       => 'controller',
	  }
	  
	  class { compact_controller: }
	  $swift_zone = $node[0]['swift_zone']

	  class { 'openstack::swift::storage_node':
	    storage_type       => $swift_loopback,
	    swift_zone         => $swift_zone,
	    swift_local_net_ip => $internal_address,
	  }

	  class { 'openstack::swift::proxy':
	    swift_user_password     => $swift_user_password,
	    swift_proxies           => $swift_proxies,
            ...
	    rabbit_ha_virtual_ip      => $internal_virtual_ip,
	  }
	}

Notice also that each controller has the swift_zone specified, so each
of the three controllers can represent each of the three Swift zones.

Similarly, site.pp defines a class for the compute nodes.

Installing Nagios Monitoring using Puppet
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Fuel provides a way to deploy Nagios for monitoring your OpenStack cluster. It will require the installation of an agent on the controller, compute, and storage nodes, as well as having a master server for Nagios which will collect and display all the results. An agent, the Nagios NRPE addon, allows OpenStack to execute Nagios plugins on remote Linux/Unix machines. The main reason for doing this is to monitor basic resources (such as CPU load, memory usage, etc.), as well as more advanced ones on remote machines.


Nagios Agent
++++++++++++

In order to install Nagios NRPE on a compute or controller node, a node should have the following settings: ::

  class {'nagios':
    proj_name       => 'test',
    services        => ['nova-compute','nova-network','libvirt'],
    whitelist       => ['127.0.0.1', $nagios_master],
    hostgroup       => 'compute',
  }

* ``proj_name``: An environment for nagios commands and the directory (``/etc/nagios/test/``).
* ``services``: All services to be monitored by nagios.
* ``whitelist``: The array of IP addreses trusted by NRPE.
* ``hostgroup``: The group to be used in the nagios master (do not forget create the group in the nagios master).

Nagios Server
+++++++++++++

In order to install Nagios Master on any convenient node, a node should have the following applied: ::

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

* ``proj_name``: The environment for nagios commands and the directory (``/etc/nagios/test/``).
* ``templatehost``: The group of checks and intervals parameters for hosts (as a Hash).
* ``templateservice``: The group of checks and intervals parameters for services  (as a Hash).
* ``hostgroups``: All groups which on NRPE nodes (as an Array).
* ``contactgroups``: The group of contacts (as a Hash).
* ``contacts``: Contacts to receive error reports (as a Hash)


Health Checks
+++++++++++++

You can see the complete definition of the available services to monitor and their health checks at ``deployment/puppet/nagios/manifests/params.pp``.

Here is the list: ::

  $services_list = {
    'nova-compute' => 'check_nrpe_1arg!check_nova_compute',
    'nova-network' => 'check_nrpe_1arg!check_nova_network',
    'libvirt' => 'check_nrpe_1arg!check_libvirt',
    'swift-proxy' => 'check_nrpe_1arg!check_swift_proxy',
    'swift-account' => 'check_nrpe_1arg!check_swift_account',
    'swift-container' => 'check_nrpe_1arg!check_swift_container',
    'swift-object' => 'check_nrpe_1arg!check_swift_object',
    'swift-ring' => 'check_nrpe_1arg!check_swift_ring',
    'keystone' => 'check_http_api!5000',
    'nova-novncproxy' => 'check_nrpe_1arg!check_nova_novncproxy',
    'nova-scheduler' => 'check_nrpe_1arg!check_nova_scheduler',
    'nova-consoleauth' => 'check_nrpe_1arg!check_nova_consoleauth',
    'nova-cert' => 'check_nrpe_1arg!check_nova_cert',
    'cinder-scheduler' => 'check_nrpe_1arg!check_cinder_scheduler',
    'cinder-volume' => 'check_nrpe_1arg!check_cinder_volume',
    'haproxy' => 'check_nrpe_1arg!check_haproxy',
    'memcached' => 'check_nrpe_1arg!check_memcached',
    'nova-api' => 'check_http_api!8774',
    'cinder-api' => 'check_http_api!8776',
    'glance-api' => 'check_http_api!9292',
    'glance-registry' => 'check_nrpe_1arg!check_glance_registry',
    'horizon' => 'check_http_api!80',
    'rabbitmq' => 'check_rabbitmq',
    'mysql' => 'check_galera_mysql',
    'apt' => 'nrpe_check_apt',
    'kernel' => 'nrpe_check_kernel',
    'libs' => 'nrpe_check_libs',
    'load' => 'nrpe_check_load!5.0!4.0!3.0!10.0!6.0!4.0',
    'procs' => 'nrpe_check_procs!250!400',
    'zombie' => 'nrpe_check_procs_zombie!5!10',
    'swap' => 'nrpe_check_swap!20%!10%',
    'user' => 'nrpe_check_users!5!10',
    'host-alive' => 'check-host-alive',
  }

Node definitions
^^^^^^^^^^^^^^^^

These are the node definitions generated for a Compact HA deployment.  Other deployment configurations generate other definitions.  For example, the ``openstack/examples/site_openstack_full.pp`` template specifies the following nodes:

* fuel-controller-01
* fuel-controller-02
* fuel-controller-03
* fuel-compute-[\d+]
* fuel-swift-01
* fuel-swift-02
* fuel-swift-03
* fuel-swiftproxy-[\d+]
* fuel-quantum

Using this architecture, the system includes three stand-alone swift-storage servers, and one or more swift-proxy servers.

With ``site.pp`` prepared, you're ready to perform the actual installation.


