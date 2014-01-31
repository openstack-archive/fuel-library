Facter.add("nailgund_ports") do
  setcode do
    num_procs = Facter.processorcount.to_i
    if num_procs > 32 then
        num_procs = 32
    end
    start_port = 8001

    [*start_port...(start_port+num_procs)].join(' ')
  end
end
