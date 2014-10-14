Puppet::Type.type(:service).provide(:monit, :parent => Puppet::Provider) do
  COMMAND = "/usr/bin/monit"

  def status
    results = `#{COMMAND} status`
    procs = results.split("\n\n")
    procs.each do |proc_info|
      lines = proc_info.split("\n")
      if lines[0].strip == "Process '#{resource[:name]}'"
        status = lines[1].split(" ")[1..-1].join(" ")
        return :stopped if status == "Not monitored"
        return :running if status == "Running"
      end
    end
    nil
  end

  def start
    `#{COMMAND} start #{resource[:name]}`
  end

  def stop
    `#{COMMAND} stop #{resource[:name]}`
  end
end
