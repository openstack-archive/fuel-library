Generating the Puppet manifest
------------------------------

Before you can deploy OpenStack, you will need to configure the site.pp file.  While previous versions of Fuel required you to manually configure ``site.pp``, version 2.1 includes the ``openstack_system`` script, which uses both the ``config.yaml`` and template files for the various reference architectures to create the appropriate Puppet manifest.  To create ``site.pp``, execute this command::

  openstack_system -c config.yaml \
    -t /etc/puppet/modules/openstack/examples/site_openstack_ha_compact.pp \
    -o /etc/puppet/manifests/site.pp \
    -a astute.yaml

The four parameters shown here represent the following:

   * ``-c``:  The absolute or relative path to the ``config.yaml`` file you customized earlier.
   * ``-t``:  The template file to serve as a basis for ``site.pp``.  Possible templates include ``site_openstack_ha_compact.pp``, ``site_openstack_ha_minimal.pp``, ``site_openstack_ha_full.pp``, ``site_openstack_single.pp``, and ``site_openstack_simple.pp``.
   * ``-o``:  The output file.  This should always be ``/etc/puppet/manifests/site.pp``.
   * ``-a``:  The orchestration configuration file, to be output for use in the next step.



From there you're ready to install your OpenStack components, but first let's look at what's actually in the new ``site.pp`` manifest, so that you can undersand how to customize it if necessary.  (Similarly, if you are installing Fuel Library without the ISO, you will need to make these customizations yourself.)
