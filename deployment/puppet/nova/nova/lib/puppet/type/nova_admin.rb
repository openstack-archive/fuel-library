Puppet::Type.newtype(:nova_admin) do

  @doc = "Manage creation/deletion of nova admin users."

  ensurable

  newparam(:name) do
    desc "The name of the admins."
  end

end
