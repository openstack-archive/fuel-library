require File.join File.dirname(__FILE__), '../rabbitmq_common.rb'

Puppet::Type.type(:rabbitmq_plugin).provide(:rabbitmqplugins, :parent => Puppet::Provider::Rabbitmq_common) do

  commands :rabbitmqplugins => 'rabbitmq-plugins'
  defaultfor :feature => :posix

  def self.instances
    self.wait_for_online
    self.run_with_retries {
      rabbitmqplugins('list', '-E')
    }.split(/\n/).map do |line|
      if line.split(/\s+/)[1] =~ /^(\S+)$/
        new(:name => $1)
      else
        raise Puppet::Error, "Cannot parse invalid plugins line: #{line}"
      end
    end
  end

  def create
    rabbitmqplugins('enable', resource[:name])
  end

  def destroy
    rabbitmqplugins('disable', resource[:name])
  end

  def exists?
    self.class.wait_for_online
    out = self.class.run_with_retries {
      rabbitmqplugins('list', '-E')
    }.split(/\n/).detect do |line|
      line.split(/\s+/)[1].match(/^#{resource[:name]}$/)
    end
  end

end
