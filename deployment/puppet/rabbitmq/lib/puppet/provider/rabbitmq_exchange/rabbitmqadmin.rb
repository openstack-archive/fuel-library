require 'puppet'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rabbitmqctl'))
Puppet::Type.type(:rabbitmq_exchange).provide(:rabbitmqadmin, :parent => Puppet::Provider::Rabbitmqctl) do

  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqctl   => 'rabbitmqctl'
    commands :rabbitmqadmin => '/usr/local/bin/rabbitmqadmin'
  else
    has_command(:rabbitmqctl, 'rabbitmqctl') do
      environment :HOME => "/tmp"
    end
    has_command(:rabbitmqadmin, '/usr/local/bin/rabbitmqadmin') do
      environment :HOME => "/tmp"
    end
  end
  defaultfor :feature => :posix

  def retry_rabbitmqctl(*args)
    self.class.run_with_retries do
      rabbitmqctl(*args)
    end
  end

  def self.retry_rabbitmqctl(*args)
    self.run_with_retries do
      rabbitmqctl(*args)
    end
  end

  def retry_rabbitmqadmin(*args)
    self.class.run_with_retries do
      rabbitmqadmin(*args)
    end
  end

  def self.retry_rabbitmqadmin(*args)
    self.run_with_retries do
      rabbitmqadmin(*args)
    end
  end

  def should_vhost
    if @should_vhost
      @should_vhost
    else
      @should_vhost = resource[:name].split('@')[1]
    end
  end

  def self.all_vhosts
    vhosts = []
    parse_command(
        retry_rabbitmqctl('list_vhosts')
    ).collect do |vhost|
        vhosts.push(vhost)
    end
    vhosts
  end

  def self.all_exchanges(vhost)
    exchanges = []
    parse_command(
        retry_rabbitmqctl('list_exchanges', '-p', vhost, 'name', 'type')
    )
  end

  def self.parse_command(cmd_output)
    # first line is:
    # Listing exchanges/vhosts ...
    # while the last line is
    # ...done.
    #
    cmd_output.split(/\n/)[1..-2]
  end

  def self.instances
    resources = []
    all_vhosts.each do |vhost|
        all_exchanges(vhost).collect do |line|
            name, type = line.split()
            if type.nil?
                # if name is empty, it will wrongly get the type's value.
                # This way type will get the correct value
                type = name
                name = ''
            end
            exchange = {
              :type   => type,
              :ensure => :present,
              :name   => "%s@%s" % [name, vhost],
            }
            resources << new(exchange) if exchange[:type]
        end
    end
    resources
  end

  def self.prefetch(resources)
    packages = instances
    resources.keys.each do |name|
      if provider = packages.find{ |pkg| pkg.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    name = resource[:name].split('@')[0]
    retry_rabbitmqadmin('declare', 'exchange', vhost_opt, "--user=#{resource[:user]}", "--password=#{resource[:password]}", "name=#{name}", "type=#{resource[:type]}", '-c', '/etc/rabbitmq/rabbitmqadmin.conf')
    @property_hash[:ensure] = :present
  end

  def destroy
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    name = resource[:name].split('@')[0]
    retry_rabbitmqadmin('delete', 'exchange', vhost_opt, "--user=#{resource[:user]}", "--password=#{resource[:password]}", "name=#{name}", '-c', '/etc/rabbitmq/rabbitmqadmin.conf')
    @property_hash[:ensure] = :absent
  end

end
