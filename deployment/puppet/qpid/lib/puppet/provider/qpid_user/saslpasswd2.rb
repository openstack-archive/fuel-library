Puppet::Type.type(:qpid_user).provide(:saslpasswd2) do

  commands :saslpasswd2 => 'saslpasswd2'
  optional_commands :sasldblistusers2 => 'sasldblistusers2'
  defaultfor :feature => :posix

  def self.instances
    sasldblistusers2('-f', resource[:file]).split(/\n/)[1..-2].map do |line|
      if line =~ /^(\S+)@(\S+):.*$/
        new(:name => $1, :realm => $2)
      else
        raise Puppet::Error, "Cannot parse invalid user line: #{line}"
      end
    end
  end

  def create
    if not system(%{echo "#{resource[:password]}" | saslpasswd2 -p -f #{resource[:file]} -u #{resource[:realm]} #{resource[:name]}})
      raise Puppet::Error, "Failed to create user."
    end
  end

  def destroy
    saslpasswd2('-f', resource[:file], '-u', resource[:realm], '-d', resource[:name])
  end

  def exists?
    if not system(%{test -f "#{resource[:file]}"})
      return false
    else
      if sasldblistusers2('-f', resource[:file]).empty?
        return false
      else
        out = sasldblistusers2('-f', resource[:file]).split(/\n/)[1..-2].detect do
          |line| line.match(/^#{resource[:name]}@#{resource[:realm]}:.*$/)
        end
      end
    end
  end
end
