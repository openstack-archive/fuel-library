Preparing for deployment
------------------------

Before you can deploy OpenStack, you will need to configure the site.pp file.  While previous versions of Fuel required you to manually configure site.pp, version 2.1 includes the ``openstack_system`` script, which uses both the ``config.yaml`` and template files for the various reference architectures to create the appropriate script.  To create site.pp, execute this script::

  openstack_system -c /tmp/config.yaml 
    -t /etc/puppet/modules/openstack/examples/site_openstack_ha_compact.pp 
    -o /etc/puppet/manifests/site.pp

From there you're ready to install your OpenStack components, but first let's look at what's actually in the script, so that you can undersand how to customize it if necessary.
