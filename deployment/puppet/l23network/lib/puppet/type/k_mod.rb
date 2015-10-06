Puppet::Type.newtype(:k_mod) do
    @doc = "Check and load kernel module, if need"
    desc @doc

    ensurable

    newparam(:module) do
      isnamevar
      desc "Module name"
    end
end
# vim: set ts=2 sw=2 et :
