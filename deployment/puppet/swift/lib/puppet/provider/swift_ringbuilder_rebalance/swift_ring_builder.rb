require 'puppet/util/execution'
require 'timeout'

Puppet::Type.type(:swift_ringbuilder_rebalance).provide(:swift_ring_builder) do
  desc "Provider for :swift_ringbuilder_rebalance"

  commands :ring_builder => "/usr/bin/swift-ring-builder"

  def balance
    debug "Call ensure for '#{@resource[:name]}' swift_ringbuilder_rebalance"
    self.get_balance
  end

  def balance=(value)
    try = 1
    rebalance_output = ""
    debug "Rebalance '#{@resource[:name]}' ring untill we get desired '#{@resource[:balance]}' balance"
    @resource[:tries].times do
      debug "Try ##{try} of #{@resource[:tries]} max tries"
      rebalance_output = self.rebalance
      return true if self.balance == value
      sleep @resource[:try_sleep]
      try += 1
    end
    self.fail "output from the last rebalance command attempt: '#{rebalance_output.chomp}'"
  end

  def run_cmd(command="")
    output=""
    begin
      Timeout::timeout(@resource[:timeout]) do
        output = Puppet::Util::Execution.execute(
                    "#{command(:ring_builder)} /etc/swift/#{@resource[:name]}.builder #{command}",
                    :failonfail => false, :combine => true, :uid => resource[:user], :override_locale => false)
      end
    rescue Timeout::Error
      self.fail "Command '#{command(:ring_builder)} /etc/swift/#{@resource[:name]}.builder #{command}' exceeded timeout"
    end
    output
  end

  def get_balance
    debug "Getting current balance '#{@resource[:name]}' ring"
    stdout = self.run_cmd
    balance = stdout.scan(/\d+(?:\.\d+)?\s+balance/).first[ /\d+(?:\.\d+)?/ ].to_f
    debug "Got balance = #{balance}"
    debug stdout
    balance
  end

  def rebalance
    debug "Rebalancing '#{@resource[:name]}' ring"
    stdout = self.run_cmd('pretend_min_part_hours_passed')
    debug stdout
    stdout = self.run_cmd('rebalance')
    debug stdout
    stdout
  end

end
