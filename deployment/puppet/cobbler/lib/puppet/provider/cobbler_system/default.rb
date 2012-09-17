require 'puppet'
Puppet::Type.type(:cobbler_system).provide(:default) do
  defaultfor :operatingsystem => [:centos, :redhat, :debian, :ubuntu]
  
  def exists?
    Puppet.info "cobbler_system: checking if system exists: #{@resource[:name]}"
    if find_system_full
      Puppet.info "cobbler_system: system exists: #{@resource[:name]}"
      return true
    else
      Puppet.info "cobbler_system: system does not exist: #{@resource[:name]}"
      return false
    end
  end

  def create
    Puppet.info "cobbler_system: updating system: #{@resource[:name]}"
    update_system
  end

  def destroy
    Puppet.info "cobbler_system: removing system: #{@resource[:name]}"
    remove_system
  end

  private

  def netboot_enabled
    if @resource[:netboot] == :true
      "True" 
    else
      "False"  
    end
  end

  def find_system_full
    system = `cobbler system find --name=#{@resource[:name]} --netboot-enabled=#{netboot_enabled} --profile=#{@resource[:profile]}`
    system.chomp
    return system.size != 0
  end

  def find_system_name
    system = `cobbler system find --name=#{@resource[:name]}`
    system.chomp
    return system.size != 0
  end

  def update_system
    subcommand = find_system_name ? 'edit' : 'add'
    system("cobbler system #{subcommand} --name=#{@resource[:name]} --netboot-enabled=#{netboot_enabled} --profile=#{@resource[:profile]}")
  end

  def remove_system
    system("cobbler system remove --name=#{@resource[:name]}")
  end

end
