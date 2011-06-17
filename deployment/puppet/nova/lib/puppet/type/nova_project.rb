Puppet::Type.newtype(:nova_project) do

  @doc = "Manage creation/deletion of nova projects."

  ensurable

  newparam(:name, :namevar => true) do
    desc "The name of the project."
  end

  newparam(:owner) do
    desc "Owner of this project. *This is only set on project creation*"
  end

  # newproperty(:owner) - this needs to be a property

  autorequire(:nova_admin) do
    [self[:owner]]
  end

end
