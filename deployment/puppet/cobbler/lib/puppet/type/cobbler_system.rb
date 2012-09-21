require 'puppet'

Puppet::Type.newtype(:cobbler_system) do

  desc = "Type to manage cobbler systems"

  ensurable do
    defaultto(:present)
    newvalue(:present) do
      provider.create
    end
    newvalue(:absent) do
      provider.destroy
    end
  end

  newparam(:profile) do
    desc "Profile"
    newvalues(/^\S+$/)
  end

  newparam(:netboot) do
    desc "If system enabled to boot over PXE"
    newvalues(:true, :false)
  end

  newparam(:name, :namevar => true) do
    desc "Name of profile"
    newvalues(/^\S+$/)
  end

end
