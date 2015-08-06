require 'puppet/node/facts'
require 'puppet/indirector/code'

class Puppet::Node::Facts::NetworkDevice < Puppet::Indirector::Code
  desc "Retrieve facts from a network device."

  # Look a device's facts up through the current device.
  def find(request)
    result = Puppet::Node::Facts.new(request.key, Puppet::Util::NetworkDevice.current.facts)

    result.add_local_facts
    Puppet[:stringify_facts] ? result.stringify : result.sanitize

    result
  end

  def destroy(facts)
    raise Puppet::DevError, "You cannot destroy facts in the code store; it is only used for getting facts from a remote device"
  end

  def save(facts)
    raise Puppet::DevError, "You cannot save facts to the code store; it is only used for getting facts from a remote device"
  end
end
