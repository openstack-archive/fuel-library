Adding and configuring custom services
--------------------------------------

Fuel is designed to help you easily install a standard OpenStack cluster, but what if your cluster is not standard? What if you need services or components that are not included with the standard Fuel distribution? This document is designed to give you all of the information you need in order to add custom services and packages to a Fuel-deployed cluster.

Fuel usage scenarios and how they affect installation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Two basic Fuel usage scenarios exist.

In the first scenario, a deployment engineer takes the Fuel ISO image, deploys the master node, makes necessary changes to configuration files, and then deploys OpenStack.  In this scenario, each node gets a clean OpenStack installation.

In the second scenario, the master node and other nodes in the cluster have already been installed, and the deployment engineer has to deploy OpenStack to an existing configuration.

For the purposes of this discussion, the main difference between these two scenarios is that service in the second scenario may be using an operating system that has already been customized; for the clean install of the first scenario, any customizations have to be performed on-the-fly, as part of the deployment.

In most cases, best practices dictate that you deploy and test OpenStack first, and then add any custom services. Fuel works using puppet manifests, so the simplest way to install a new service is to edit the current site.pp file on the Puppet master machine and start an additional deployment paths on the target node.

While that is the ideal means for installing a new service or component, it's not an option in situations in which OpenStack actually requires the new service or component. For example, hardware drivers and management software often must be installed before OpenStack itself. You still, however, have the option to create a separate customized site.pp file and run a deployment pass before installing OpenStack. One advantage to this method is that any version mismatches between the component and OpenStack dependencies should be easy to isolate.

Finally, if this is not an option, you can inject a custom component installation into the existing fuel manifests. If you elect to go this route, you'll need to be aware of software source compatibility issues, as well as installation stages, component versions, incompatible dependencies, and declared resource names.

In short, simple custom component installation may be accomplished by editing the site.pp file, but more complex components should be added as new Fuel components. 

Let's look at what you need to know.

Installing the new service along with Fuel
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When it comes to installing your new service or component alongside Fuel, you have several options. How you go about it depends on where in the process the component needs to be available. Let's look at each step and how it can impact your installation.

**Boot the master node**

In most cases, you will be installing the master node from the Fuel ISO. This is a semiautomatic step, and doesn't allow for any custom components. If for some reason you need to install a node at this level, you will need to use the manual Fuel installation procedure.

**Cobbler configuration**

If your customizations need to take place before the install of the operating system, or even as part of the operating system install, you can do them at this step. This is also where you would make customizations to other services. At this level, you are making changes to the operating system kickstart/pre-seed files, and may include any custom software source and components required to install the operating system for a node. Anything that needs to be installed before OpenStack should be configured during this step.

**OpenStack installation**

It is during this step that you perform any Puppet, Astute, or mCollective configuration. In most cases, this means customizing the Puppet site.pp file to add any custom components during the actual OpenStack installation.

This step actually includes several different stages. (In fact, Puppet STDLib defines several additional default stages that fuel does not use.) These stages include:

0. ``Puppetlabs-repo``. mCollective uses this stage to add the Puppetlabs repositories during operating system and Puppet deployment.

1. ``Openstack-custom-repo``. Additional repositories required by OpenStack are configured at this stage. Additionally, to avoid compatibility issues, the Puppetlabs repositories are switched off at this stage. As a general rule, it is a good idea to turn off any unnecessary software repositories defined for operating system installation.

2. ``FUEL``.  During this stage, Fuel performs any actions defined for the current operating system.

3. ``Netconfig``. During this stage, Fuel performs all network configuration actions. This means that you should include any custom components that are related to the network in this stage.

4. ``Main``. The actual OpenStack installation process happens during this stage. Install any non-network-related components during this stage or after it.

**Post-OpenStack install**

At this point, OpenStack is installed. You may add any components you like at this point, as long as they don't break OpenStack itself.

Defining a new component
^^^^^^^^^^^^^^^^^^^^^^^^

In general, we recommend you follow these steps to define a new component:

#. **Custom stages. Optional.**

   Declare a custom stage or stages to help Puppet understand the required installation sequence.
   Stages are special markers indicating the sequence of actions. Best practice is to use the input parameter Before for every stage, to help define the correct sequence. The default built-in stage is "main". Every Puppet action is automatically assigned to the main stage if no stage is explicitly specified for the action. However, because Fuel installs almost all of OpenStack during the main stage, custom stages may not help, so future plans include breaking the OpenStack installation to several stages.

   Don't forget to take into account other existing stages; training several parallel sequences of stages increases the chances that Puppet will order them in correctly if you do not explicitly specify the order.

   *Example*::
   
      stage {'Custom stage 1':
         before  => Stage['Custom stage 2'],
      }
      stage {'Custom stage 2':
         before  => Stage['main'],
      }

   Note that there are several limitations to stages, and they should be used with caution and only with the simplest of classes. You can find more information here:  http://docs.puppetlabs.com/puppet/2.7/reference/lang_run_stages.html.
  
#. **Custom repositories. Optional.**

   If the custom component requires a custom software source, you may declare a new repository and add it during one of the early stages of the installation.  
   
#. **Common variable definition**

   It is a good idea to have all common variables defined in a single place. Unlike variables in many other languages, Puppet  variables are actually constants, and may be assigned only once inside a given scope.
   
#. **OS and condition-dependent variable definition**

   It is also a good idea to assign all common operating system or condition-dependent variables to a single location, preferably near the other common variables. Also, be sure to always use a default section when defining conditional operators.

*Example*::

   case $::osfamily {
      # RedHat in most cases should work for CentOS and Fedora as well
      'RedHat': {
         # List of packages to get from URL/path.
         # Separate list should be defined for each separate URL!
         $custom_package_list_from_url = ['qpid-cpp-server-0.14-16.el6.x86_64.rpm']
      }
      'Debian': {
         # List of packages to get from URL/path.
         # Separate list should be defined for each separate URL!
         $custom_package_list_from_url = [ "qpidd_0.14-2_amd64.deb" ]
      }
      default: {
         fail("Module install_custom_package does not support ${::operatingsystem}")
      }
   }

#. **Define installation procedures for independent custom components as classes**

   You can think of public classes as singleton collections, or simply as a named block of code with its own namespace. Each class should be defined only once, but every class may be used with different input variable sets. The best practice is to define a separate class for every component, define required sub-classes for sub-components, and include class-dependent required resources within the actual class/subclass.

*Example*::

   class add_custom_service (
      # Input parameter definitions:
         # Name of the service to place behind HAProxy. Mandatory.
         # This name appears as a new HAProxy configuration block in /etc/haproxy/haproxy.cfg.
         $service_name_in_haproxy_config,
         $custom_package_download_url,
         $custom_package_list_from_url,
         #The list of remaining input parameters
         ...
   ) {
   # HAProxy::params is a container class holding default parameters for the haproxy class. It adds and populates the Global and Default sections in /etc/haproxy/haproxy.cfg.
   # If you install a custom service over the already deployed HAProxy configuration, it is probably better to comment out the following string:
   include haproxy::params
   #Class resources definitions:
       # Define the list of package names to be installed
       define install_custom_package_from_url (
          $custom_package_download_url,
          $package_provider = undef
       ) {
          exec { "download-${name}" :
                 command     => "/usr/bin/wget -P/tmp ${custom_package_download_url}/${name}",
                 creates     => "/tmp/${name}",
          } ->
          install_custom_package { "${name}" :
                 provider    => $package_provider,
                 source      => "/tmp/${name}",
          }
         }
      define install_custom_package (
         $package_provider = undef,
         $package_source = undef
      ) {
         package { "custom-${name}" :
                   ensure      => present,
                   provider    => $package_provider,
                   source      => $package_source
         }
        }
  
      #Here we actually install all the packages from a single URL.
      if is_array($custom_package_list_from_url) {
          install_custom_package_from_url { $custom_package_list_from_url :
              provider    => $package_provider,
              custom_package_download_url => $custom_package_download_url,
          }
      }
    }

#. **Target nodes**

   Every component should be explicitly assigned to a particular target node or nodes.  
   To do that, declare the node or nodes within site.pp. When Puppet runs the manifest for each node, it compares each node definition with the name of the current hostname and applies only to classes assigned to the current node.  Node definitions may include regular expressions. For example, you can apply the class 'add custom service' to all controller nodes with hostnames fuel-controller-00 to fuel-controller-xxx, where xxx = any integer value using the following definition:

*Example*::

   node /fuel-controller-[\d+]/ {
     include stdlib
     class { 'add_custom_service':
       stage => 'Custom stage 1',
       service_name_in_haproxy_config => $service_name_in_haproxy_config,
       custom_package_download_url => $custom_package_download_url,
       custom_package_list_from_url => $custom_package_list_from_url,
     }
   }

Fuel API Reference
^^^^^^^^^^^^^^^^^^   

**add_haproxy_service**
Location: Top level

As the name suggests, this function enables you to create a new HAProxy service.  The service is defined in the ``/etc/haproxy/haproxy.cfg`` file, and generally looks something like this::

    listen keystone-2
      bind 10.0.74.253:35357
      bind 10.0.0.110:35357
      balance  roundrobin
      option  httplog
      server  fuel-controller-01.example.com 10.0.0.101:35357   check  
      server  fuel-controller-02.example.com 10.0.0.102:35357   check  

To accomplish this, you might create a Fuel statement such as::

    add_haproxy_service { 'keystone-2' :
        order => 30,
        balancers => {'fuel-controller-01.example.com' => '10.0.0.101', 
                      'fuel-controller-02.example.com' => '10.0.0.102'},
        virtual_ips => {'10.0.74.253', '10.0.0.110'},
        port => '35357',
        haproxy_config_options => { 'option' => ['httplog'], 'balance' => 'roundrobin' },
        balancer_port => '35357',
        balancermember_options => 'check',
        mode => 'tcp',
        define_cookies => false,
        define_backend => false,
        collect_exported => false
        }

Let's look at how the command works.

**Usage:** ::

    add_haproxy_service { '<SERVICE_NAME>' :
        order => $order,
        balancers => $balancers,
        virtual_ips => $virtual_ips,
        port => $port,
        haproxy_config_options => $haproxy_config_options,
        balancer_port => $balancer_port,
        balancermember_options => $balancermember_options,
        mode => $mode, #Optional. Default is 'tcp'.
        define_cookies => $define_cookies, #Optional. Default false.
        define_backend => $define_backend,#Optional. Default false.
        collect_exported => $collect_exported, #Optional. Default false.
        }

**Parameters:**

``<'Service name'>``

The name of the new HAProxy listener section. In our example it was ``keystone-2``. If you want to include an IP address or port in the listener name, you have the option to use a name such as:: 

    'stats 0.0.0.0:9000       #Listen on all IP's on port 9000'

``order``

This parameter determines the order of the file fragments. It is optional, but we strongly recommend setting it manually.
Fuel already has several different order values from 1 to 100 hardcoded for HAProxy configuration. So if your HAProxy configuration fragments appear in the wrong places in ``/etc/haproxy/haproxy.cfg``, it is probably because of an incorrect order value. It is safe to set order values greater than 100 in order to place your custom configuration block at the end of ``haproxy.cfg``.

Puppet assembles configuration files from fragments. First it creates several configuration fragments and temporarily stores all of them as separate files. Every fragment has a name such as ``${order}-${fragment_name}``, so the order determines the number of the current fragment in the fragment sequence.
After all the fragments are created, Puppet reads the fragment names and sorts them in ascending order, concatenating all the fragments in that order. So a fragment with a smaller order value always goes before all fragments with a greater order value.

The ``keystone-2`` fragment from the example above has ``order = 30`` so it's placed after the ``keystone-1`` section (``order = 20``) and the ``nova-api-1`` section (order = 40).

``balancers``

Balancers (or **Backends** in HAProxy terms) are a hash of ``{ "$::hostname" => $::ipaddress }`` values.
The default is ``{ "<current hostname>" => <current ipaddress> }``, but that value is set for compatability only, and may not work correctly in HA mode.  Instead, the default for HA mode is to explicitly set the Balancers as ::

    Haproxy_service {
      balancers => $controller_internal_addresses
  }

which ``$controller_internal_addresses`` representing a hash of all the controllers with a corresponding internal IP address; this value is set in ``site.pp``.

So the ``balancers`` parameter is a list of HAProxy listener balance members (hostnames) with corresponding IP addresses. The following strings from the ``keystone-2`` listener example represent balancers::

    server  fuel-controller-01.example.com 10.0.0.101:35357   check  
    server  fuel-controller-02.example.com 10.0.0.102:35357   check  

Every key pair in the ``balancers`` hash adds a new string to the list of listener section balancers. Different options may be set for every string.

``virtual_ips``

This parameter represents an array of IP addresses (or **Frontends** in HAProxy terms) of the current listener. Every IP address in this array adds a new string to the bind section of the current listeners. The following strings from the ``keystone-2`` listener example represent virtual IPs::

    bind 10.0.74.253:35357
    bind 10.0.0.110:35357

``port``

This parameters specifies the frontend port for the listeners. Currently you must set the same port frontends.
The following strings from the ``keystone-2`` listener example represent the frontend port, where the port is 35357::

    bind 10.0.74.253:35357
    bind 10.0.0.110:35357

``haproxy_config_options``

This parameter represents a hash of key pairs of HAProxy listener options in the form ``{ 'option name' => 'option value' }``.   Every key pair from this hash adds a new string to the listener options.
Please note: Every HAProxy option may require a different input value type, such as strings or a list of multiple options per single string.

The '`keystone-2`` listener example has the ``{ 'option' => ['httplog'], 'balance' => 'roundrobin' }`` option array and this array is represented as the following in the resulting /etc/haproxy/haproxy.cfg:
balance  roundrobin
option  httplog

``balancer_port``

This parameter represents the balancer (backend) port. By default, the balancer_port is the same as the frontend ``port``. The following strings from the ``keystone-2`` listener example represent ``balancer_port``, where port is ``35357``::

    server  fuel-controller-01.example.com 10.0.0.101:35357   check  
    server  fuel-controller-02.example.com 10.0.0.102:35357   check  

``balancermember_options``

This is a string of options added to each balancer (backend) member. The ``keystone-2`` listener example has the single ``check`` option::

    server  fuel-controller-01.example.com 10.0.0.101:35357   check  
    server  fuel-controller-02.example.com 10.0.0.102:35357   check  

``mode``

This optional parameter represents the HAProxy listener mode. The default value is ``tcp``, but Fuel writes ``mode http`` to the defaults section of ``/etc/haproxy/haproxy.cfg``. You can set the same option via  ``haproxy_config_options``. A separate mode parameter is required to set some modes by default on every new listener addition. The ``keystone-2`` listener example has no ``mode`` option and so it works in the default Fuel-configured HTTP mode.

``define_cookies``

This optional boolean parameter is a Fuel-only feature.  The default is ``false``, but if set to ``true``, Fuel directly adds ``cookie ${hostname}`` to every balance member (backend).

The ``keystone-2`` listener example has no ``define_cookies`` option. Typically, frontend cookies are added with ``haproxy_config_options`` and backend cookies with ``balancermember_options``.

``collect_exported``

This optional boolean parameter has a default value of ``false``.  True means 'collect exported @@balancermember resources' (when every balancermember node exports itself), while false means 'rely on the existing declared balancermember resources' (for when you know the full set of balancermembers in advance and use ``haproxy::balancermember`` with array arguments, which allows you to deploy everything in one run).
