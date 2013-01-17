Puppet module providing things for Open vSwitch. 

Current layout is:
bridges - A "Bridge" is basically the thing you plug ports / interfaces into.
ports - A Port is a interface you plug into the bridge (switch).

USAGE:
Place this directory at:
<your module directory of choice>/ovs

Then in your manifest you can either use the things as parameterized classes:
class {"ovs": }
ovs::bridge{"br-ex":
    name => "br-ex"
}
ovs::port{"eth0": 
    interface => "eth0",
    bridge    => "br-ex"
}
ovs::port{"kkk0": 
    interface => "kkk0",
    bridge    => "br-ex"
}
ovs::port{"kkk1": 
    interface => "kkk1",
    bridge    => "br-ex"
}

---
this module based on https://github.com/ekarlso/puppet-vswitch
