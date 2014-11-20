require File.join File.dirname(__FILE__), '../rabbitmq_common.rb'

Puppet::Type.type(:rabbitmq_vhost).provide(:rabbitmqctl, :parent => Puppet::Provider::Rabbitmq_common) do

  #TODO: change optional_commands -> commands when puppet >= 3.0
  optional_commands :rabbitmqctl => 'rabbitmqctl'
  defaultfor :feature => :posix

  def self.instances
    self.wait_for_online
    self.run_with_retries {
      rabbitmqctl('list_vhosts')
    }.split(/\n/)[1..-2].map do |line|
      if line =~ /^(\S+)$/
        new(:name => $1)
      else
        raise Puppet::Error, "Cannot parse invalid user line: #{line}"
      end
    end
  end

  def create
    rabbitmqctl('add_vhost', resource[:name])
  end

  def destroy
    rabbitmqctl('delete_vhost', resource[:name])
  end

  def exists?
    self.class.wait_for_online
    out = self.class.run_with_retries {
      rabbitmqctl('list_vhosts')
    }.split(/\n/)[1..-2].detect do |line|
      line.match(/^#{Regexp.escape(resource[:name])}$/)
    end
  end

end
