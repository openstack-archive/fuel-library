Puppet module providing things for vSwitches. At the moment OVS is the only
one I've added but please feel free to pull request this!

It's based upon types & providers so we can support more then just OVS or one
vSwitch type.

Current layout is:
bridges - A "Bridge" is basically the thing you plug ports / interfaces into.
ports - A Port is a interface you plug into the bridge (switch).

USAGE:
Place this directory at:
<your module directory of choice>/vswitch

Then in your manifest you can either use the things as parameterized classes:
class {"vswitch::bridge":
    name => "br-ex"
}
class {"vswitch::port": 
    interface => "eth0",
    bridge    => "br-ex"
}

Or you can use them as "Providers":
vs_bridge {"br-ex":}
vs_port {"eth0": bridge => "br-ex"}

TODO:
* OpenFlow controller settings
* OpenFlow Settings
* OpenFlow Tables
* More facts
* Others that are not named here
