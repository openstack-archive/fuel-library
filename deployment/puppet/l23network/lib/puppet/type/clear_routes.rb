Puppet::Type.newtype(:clear_routes) do
    @doc = "Clear default routes with any metric"
    desc @doc

    ensurable

    newparam(:route) do
      isnamevar
      desc "The name of default route"
    end

end
# vim: set ts=2 sw=2 et :
