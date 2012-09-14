Puppet::Type.type(:firewall).provide(:lokkit) do
    desc 'Use lokkit utility to manage iptables.'

    commands :lokkit => '/usr/sbin/lokkit'
    commands :iptables => '/sbin/iptables'

    def self.prefetch(resource)
      # rebuild the cahce for every puppet run
      @iptables_hash = build_iptables_hash
    end
  
    def self.iptables_hash
      @iptables_hash ||= build_iptables_hash
    end
  
    def iptables_hash
      self.class.iptables_hash
    end
  
    def self.instances
      iptables_hash.collect do |k, v|
        new(:name => k)
      end
    end

    def self.build_iptables_hash
        hash = {}
        File.new('/etc/sysconfig/iptables').readlines.each do |line|
            if line =~ /^-A INPUT.*--dport (\d+).*-j ACCEPT$/
                hash[$1] = 1
            end
        end
        hash
    end

    # def ensure
    #     iptables_config = File.new('/etc/sysconfig/iptables')
    #     denied = iptables_config.grep(/^-A INPUT.*--dport #{port}.*-j ACCEPT$/).empty?
    #     notice("*** denied: #{denied}")
    #     denied ? :deny : :allow
    # end
    
    def exists?
        iptables_config = File.new('/etc/sysconfig/iptables')
        denied = iptables_config.grep(/^-A INPUT.*--dport #{port}.*-j ACCEPT$/).empty?
        #notice("*** denied: #{denied}")
        #denied ? :deny : :allow
        !denied
    end


    def create
        notice("*** allow: #{port}")
        # port_proto = @resource[:name] + ':' + @resource[:proto]
        port_proto = @resource[:name] + ':tcp'
        # if @resource[:port]
            lokkit '--port', port_proto
        # else
        #     lokkit '--service', @resource[:name]
        # end
    end

    def destroy
        notice("*** deny: #{port}")
        iptables_new = []
        # File.new('/etc/sysconfig/iptables').readlines.each do |line|
        #     unless line =~ /^-A INPUT.*--dport #{port}.*-j ACCEPT$/
        #         iptables_new << line
        #         notice("*** deny: #{line}")
        #     end
        # end

        File.open("/etc/sysconfig/iptables", "r") do |infile|
            while (line = infile.gets)
                unless line =~ /^-A INPUT.*--dport #{port}.*-j ACCEPT$/
                    iptables_new << line
                     notice("*** deny: #{line}")
                end
            end
        end

        # File.new('/etc/sysconfig/iptables', 'w').write iptables_new.join
        File.open('/etc/sysconfig/iptables', 'w') {|f| f.write(iptables_new.join) }

        iptables '-D', 'INPUT', '-m', 'state', '--state', 'NEW', '-m', 'tcp',
                 '-p', 'tcp', '--dport', port, '-j', 'ACCEPT'
    end

    private

    # def port
    #     if @resource[:port]
    #         return @resource[:port].split(':')[0]
    #     end
    #     name = @resource[:name]
    #     services = File.new('/etc/services').readlines.grep /^#{name}\s/
    #     raise Puppet::Error, "Cannot find #{name} service" if services.empty?
    #     services[0].split[1].split('/')[0]
    # end

    def port
        @resource[:name]
    end

end
