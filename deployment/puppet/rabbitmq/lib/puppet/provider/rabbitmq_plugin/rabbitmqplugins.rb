require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rabbitmqctl'))
Puppet::Type.type(:rabbitmq_plugin).provide(:rabbitmqplugins, :parent => Puppet::Provider::Rabbitmqctl) do

  if Puppet::PUPPETVERSION.to_f < 3
    if Facter.value(:osfamily) == 'RedHat'
      commands :rabbitmqplugins => '/usr/lib/rabbitmq/bin/rabbitmq-plugins'
    else
      commands :rabbitmqplugins => 'rabbitmq-plugins'
    end
  else
    if Facter.value(:osfamily) == 'RedHat'
      has_command(:rabbitmqplugins, '/usr/lib/rabbitmq/bin/rabbitmq-plugins') do
        environment :HOME => "/tmp"
      end
    else
      has_command(:rabbitmqplugins, 'rabbitmq-plugins') do
        environment :HOME => "/tmp"
      end
    end
  end

  defaultfor :feature => :posix

  def retry_rabbitmqplugins(*args)
    self.class.run_with_retries do
      rabbitmqplugins(*args)
    end
  end

  def self.retry_rabbitmqplugins(*args)
    self.run_with_retries do
      rabbitmqplugins(*args)
    end
  end

  def self.instances
    retry_rabbitmqplugins('list', '-E', '-m').split(/\n/).map do |line|
      if line =~ /^(\S+)$/
        new(:name => $1)
      else
        raise Puppet::Error, "Cannot parse invalid plugins line: #{line}"
      end
    end
  end

  def create
    retry_rabbitmqplugins('enable', resource[:name])
  end

  def destroy
    retry_rabbitmqplugins('disable', resource[:name])
  end

  def exists?
    retry_rabbitmqplugins('list', '-E', '-m').split(/\n/).detect do |line|
      line.match(/^#{resource[:name]}$/)
    end
  end

end
