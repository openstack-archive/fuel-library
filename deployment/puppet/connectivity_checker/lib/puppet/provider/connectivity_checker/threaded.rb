require 'yaml'

Puppet::Type.type(:connectivity_checker).provide(:threaded) do
  defaultfor :kernel   => :linux
  commands   :ping   => 'ping'  # not used, but accounted while default provider

  def ensure
    :absent
  end

  def ensure=(value)
    # calculate host hash
    network_scheme   = @resource[:network_scheme]
    network_metadata = @resource[:network_metadata]

    actual_endpoints = network_scheme['endpoints'].reject{|k,v| v['IP'].empty? or v['IP'].include?('dhcp') or v['IP'] == 'none' or !v['IP'] }
    roles_for_test   = network_scheme['roles'].select{|k,v| actual_endpoints.keys.include?(v)}

    # generate test-scheme for this node
    test_scheme = {}
    actual_endpoints.keys.each do |enp|
      test_scheme[enp] = roles_for_test.select{|k,v| v==enp}.keys()
    end
    #puts test_scheme.to_yaml()

    # process nodes from network_metadata and construct test plan, corresponded test_scheme
    test_plan = {}
    network_metadata['nodes'].each do |nodename, node_attrs|
      net_roles = node_attrs['network_roles'].select{|k,v| roles_for_test.include?(k)}
      test_plan[nodename] = {}
      test_scheme.each do |ntwrk, ntrls|
        ipaddr = net_roles.select{|k,v| ntrls.include?(k)}.values.sort.uniq[0]
        next if ipaddr.to_s == ''
        test_plan[nodename][ntwrk] = {
          :host  => ipaddr,
          :tries => @resource[:ping_tries],
          :timeout => @resource[:ping_timeout],
        }
      end
    end
    #puts test_plan.to_yaml()

    # test (ping) neighboors
    work = {}
    # fork per-host worker for parallel pinging.
    test_plan.each do |nodename, networks|
      work[nodename] = {}
      work[nodename][:thr] = Thread.new(nodename, networks) do |nodename, networks|
        #Thread.current[:nodename] = nodename
        Thread.current[:errors] = []
        networks.each do |netname, netattrs|
          Thread.current[:cmd] = "ping -n -q -c #{netattrs[:tries]} -w #{netattrs[:timeout]} #{netattrs[:host]}"
          Thread.current[:rc] = 0
          if ! system(Thread.current[:cmd], {:out => :close, :err => :close})
            Thread.current[:rc] = $?.exitstatus()
            Thread.current[:errors] << {
              :rc  => Thread.current[:rc],
              :cmd => "command `#{Thread.current[:cmd]}` was failed with code #{Thread.current[:rc]}",
              :net => netname
            }
          end
        end
      end
    end
    # waitall only for all pinger threads
    work.each do |nodename, rrr|
      rrr[:thr].join()
    end
    # process results
    err_report = {}
    work.each do |nodename, rrr|
      if ! rrr[:thr][:errors].empty?
        err_report[nodename] = []
        rrr[:thr][:errors].each do |err|
          err_report[nodename] << "Unaccessible through '#{err[:net]}', #{err[:cmd]}"
        end
      end
    end

    if ! err_report.empty?
      msg = "Connectivity check error. Nodes: #{err_report.to_yaml.sub!('---','')}"
      if @resource[:non_destructive].to_s == 'true'
        warn(msg)
      else
        fail(msg)
      end
    end
    return :present
  end

end