Facter.add("cakey") do
  setcode do
    require 'puppet'
    if Puppet::PUPPETVERSION.split(".").first == "2"
    	Puppet.settings.parse
    else 
    	Puppet.settings.initialize_global_settings unless Puppet.settings.global_defaults_initialized?
    end
    Puppet[:cakey]
  end
end