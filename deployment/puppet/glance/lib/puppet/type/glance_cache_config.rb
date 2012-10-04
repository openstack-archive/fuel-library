Puppet::Type.newtype(:glance_cache_config) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Section/setting name to manage from glance-cache.conf'
    newvalues(/\S+\/\S+/)
  end

  newproperty(:value) do
    desc 'The value of the setting to be defined.'
    munge do |v|
      v.to_s.strip
    end
  end


end
