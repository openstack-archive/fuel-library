# puppet-network

Network management for puppet

## Overview

This module provides types for network management :

 *   Device configuration files using the `network_config` type
 *   Live network management using the `network_interface` type

Note: `network_interface` and `network_config` types are not dependant on each other in any way. `network_interface` is experimental.

**Word of warning** : if you choose to go for automatic network reconfiguration and you inject a mistake in your configuration, you probably willl loose network connectivity on the configured system.

Ensure that you have a fallback ready before trying puppet-network, like physical access, a remote KVM, or similar devices so that you can restore connectivity in the event of configuration errors.

## The 'network_config' type

The `network_config` type is used to maintain persistent network configuration.
Only redhat-derivatives (RHEL,Fedora,CentOS) are currently supported.

### Important notes

#### 'Exclusive' mode by default

`puppet-network` will remove any device that is not configured through puppet-network.
This may look harsh to some, but the alternative yields greater problems (read below).

If you want `puppet-network` to leave your existing ifcfg files be, set `exclusive => false` in any of the existing network_config resources.

In non-exclusive mode, you get the freedom to handle ifcfg files the way you prefer. Be aware though, that *leaving behind unwanted devices can have very adverse effects* (broadcast issues, non-functionning bridges, defective bonding etc..) that won't be solved by rebooting the machine, probably requiring manual intervention to restore connectivity.

#### 'service network restart' issues

Phasing out a configuration is dangerous. `service network restart` will only shut down devices configured that are configured (ie with a matching file in `/etc/sysconfig/network-scripts`).

This can yield to problematic roll-outs, such as removing bridge devices. This would leave behind live bridge configuration, preventing regular use of the formerly bridged interfaces.

**Workarounds**:

 *   use `network-restart.rb` script that comes with puppet-network. this will `service network stop` then proceed to remove anything left that looks like network-configuration, then run `service network start`. Please review code first, be `--sure`, and send feedback at heliostech if you encounter issues.
 *   use `brctl`/`ifenslave`/`ip` etc manually (ie. roll your own 'network-restart.xx')
 *   use puppet in offline mode, trigger a `service network stop` before applying configuration changes (puppet code left as an exercise ..), apply changes, then do `service network start`. (*not tested*)
 *   send patches for network_interface puppet type that can do the `brctl` (and ifenslave etc..) lifting.
 *   worst case scenario, reset your computer using any appropriate way

### Samples

#### Static configuration
<pre>
network_config { "eth0":
    bootproto     => "none",
    onboot        => "yes",
    netmask       => "255.255.255.0",
    broadcast     => "192.168.56.255",
    ipaddr        => "192.168.56.101",
    userctl       => "no",
    hwaddr        => "08:00:27:34:05:15",
    domain        => "example.domain.com",
    nozeroconf    => "yes",
}
</pre>

You could also use `prefix => 24` instead of the `broadcast` parameter.

#### DHCP
<pre>
network_config { "eth0":
    bootproto     => "dhcp",
    onboot        => "yes",
}
</pre>

#### VLAN
<pre>
network_config { "eth0.2":
    vlan          => "yes",
}
</pre>

#### Bridges
<pre>
network_config { "eth0":
    bridge        => "br0"
}

network_config { "br1":
    type          => "Bridge",
    bootproto     => "dhcp",
    stp           => "on",
}
</pre>

#### Bonding
<pre>
network_config { "bond0":
    type          => "Bonding",
    bonding_module_opts => "mode=balance-rr miimon=100",
}

network_config { "eth0": master => "bond0", slave => "yes" }
network_config { "eth2": master => "bond0", slave => "yes" }
network_config { "eth3": master => "bond0", slave => "yes" }
</pre>

See [kernel documentation for bonding](http://www.kernel.org/doc/Documentation/networking/bonding.txt) for more information.

## The 'network_interface' type

The `network_interface` maintains live state of the interface using the `ip` tool, likewise :

<pre>
network_interface { "eth0":
    state     => "up",
    mtu       => "1000",
    qlen      => "1500",
    address   => "aa:bb:cc:dd:ee:ff",
    broadcast => "ff:ff:ff:ff:ff:ff",
}
</pre>

Source code
-----------

The source code for this module is available online at
    http://github.com/heliostech/puppet-network.git

You can checkout the source code by installing the `git` distributed version
control system and running:

    git clone git://github.com/heliostech/puppet-network.git

Authors
-------

 *   William Van Hevelingen <wvan13@gmail.com>
 *   Elie Bleton <ebleton@heliostech.fr>
 *   Camille Meulien <cmeulien@heliostech.fr>