Puppet::Type.newtype(:glance_registry_paste_ini) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Section/setting name to manage from glance-registry-paste.ini'
    newvalues(/\S+\/\S+/)
  end

  newproperty(:value) do
    desc 'The value of the setting to be defined.'
    munge do |v|
      v.to_s.strip
    end
  end


end
