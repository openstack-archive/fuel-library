# PuppetLabs Glance module #

This module provides a set of manifests that can be
used to install and configure glance.

It is currently targettting the essex release of OpenStack.

For Daiblo support, use the Diablo branch.

# Platforms #

  Ubuntu 11.04 (Natty)
  Ubuntu 11.10 (Oneiric)

# Quick Start #

  The below examples shows how the classes from this module can be
  declared in site.pp to install both the glance registry and api services on
  a node identified as glance.

  In the below example, the default port for the registy service has been
  overridden from its default value of 9191.

  node glance {
    class { 'glance::registry':
      bind_port => '9393',
    }
    class { 'glance::api':
      registry_port = '9393',
    }
  }
