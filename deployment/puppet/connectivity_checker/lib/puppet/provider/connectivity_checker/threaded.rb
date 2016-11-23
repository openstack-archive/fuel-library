require 'yaml'

Puppet::Type.type(:connectivity_checker).provide(:threaded) do
  defaultfor :kernel   => :linux
  commands   :ping   => 'ping'  # not used, but accounted while default provider

  def ensure
    :absent
  end

  def ensure=(value)
    # calculate host hash
    network_scheme        = @resource[:network_scheme]
    parallel_amount       = @resource[:parallel_amount]
    network_metadata      = @resource[:network_metadata]
    exclude_network_roles = @resource[:exclude_network_roles]

    actual_endpoints = network_scheme['endpoints'].reject{|k,v| v['IP'].empty? or v['IP'].include?('dhcp') or v['IP'] == 'none' or !v['IP'] }
    roles_for_test   = network_scheme['roles'].select{|k,v| actual_endpoints.keys.include?(v) && !exclude_network_roles.include?(k)}

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

    workers = {}
    # Tasks for verification.
    ping_in_q = Queue.new
    # Contains connectivity errors.
    ping_err_q = Queue.new

    test_plan.each do |nodename, networks|
      networks.each do |netname, netattrs|
        ping_in_q.push({
          :netname => netname,
          :nodename => nodename,
          :cmd => "ping -n -q -c #{netattrs[:tries]} -w #{netattrs[:timeout]} #{netattrs[:host]}"})
      end
    end

    (0..parallel_amount).each do |n|
      workers[n] = Thread.new do
        begin
          while task = ping_in_q.pop(true)
            unless system(task[:cmd], {:out => :close, :err => :close})
              exit_status = $?.exitstatus()
              ping_err_q << {
                :rc  => exit_status,
                :cmd => "command `#{task[:cmd]}` was failed with code #{exit_status}",
                :net => task[:netname],
                :nodename => task[:nodename]
              }
            end
          end
        rescue ThreadError
          # If Queue is empty, it reaises ThreadError, we are not interested
          # in proceeding after we checked all addresses in queue.
        end
      end
    end

    # Wait all for all threads to finish.
    workers.each do |_, worker|
      worker.join()
    end

    # Process results.
    err_report = {}
    unless ping_err_q.empty?
      begin
        while err = ping_err_q.pop(true)
          unless err_report[err[:nodename]]
            err_report[err[:nodename]] = []
          end
          err_report[err[:nodename]] << "Unaccessible through '#{err[:net]}', #{err[:cmd]}"
        end
      rescue ThreadError
      end
    end

    unless err_report.empty?
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
