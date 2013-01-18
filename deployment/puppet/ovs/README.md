Puppet module providing things for Open vSwitch. 

Current layout is:
bridges - A "Bridge" is basically the thing you plug ports / interfaces into.
ports - A Port is a interface you plug into the bridge (switch).

USAGE:
Place this directory at:
<your module directory of choice>/ovs

Then in your manifest you can either use the things as parameterized classes:

class {"ovs": }

ovs::bridge{"br-mgmt": }
ovs::port{"eth0": bridge => "br-mgmt"}
ovs::port{"mmm0": bridge => "br-mgmt"}
ovs::port{"mmm1": bridge => "br-mgmt"}

ovs::bridge{"br-ex": }
ovs::port{"eth0": bridge => "br-ex"}
ovs::port{"eee0": bridge => "br-ex"}
ovs::port{"eee1": bridge => "br-ex"}

---
this module based on https://github.com/ekarlso/puppet-vswitch
