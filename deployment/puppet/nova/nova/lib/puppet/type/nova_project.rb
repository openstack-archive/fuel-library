Puppet::Type.newtype(:nova_project) do

  @doc = "Manage creation/deletion of nova projects."
       
  ensurable

  newparam(:name) do
    desc "The name of the project."
  end

  newparam(:owner) do
    desc "Owner of this project."
  end
end
