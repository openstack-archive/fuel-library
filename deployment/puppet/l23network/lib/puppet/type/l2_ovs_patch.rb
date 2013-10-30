Puppet::Type.newtype(:l2_ovs_patch) do
    @doc = "Manage a Open vSwitch patch between two bridges"
    desc @doc

    ensurable

    newparam(:name) # workarround for following error:
    # Error 400 on SERVER: Could not render to pson: undefined method `merge' for []:Array
    # http://projects.puppetlabs.com/issues/5220

    newparam(:bridges, :array_matching => :all) do
      desc "Array of bridges that will be connected"
      #
      validate do |val|
        if !val.is_a?(Array) or val.size() != 2
          fail("Must be an array of two bridge names")
        end
        if not (val[0].is_a?(String) and val[1].is_a?(String))
          fail("Bridge names must have be a string.")
        end
      end
    end

    newparam(:peers, :array_matching => :all) do
      defaultto([nil,nil])
      desc "List of names that will be used for naming patches at it's ends."
      #
      validate do |val|
        if !val.is_a?(Array) or val.size() != 2
          fail("Must be an array of two bridge names")
        end
        for i in val
          if not (i.is_a?(String) or i == nil)
            fail("Peer names must have be a string.")
          end
        end
      end
    end

    # newparam(:skip_existing) do
    #   defaultto(false)
    #   desc "Allow to skip existing bond"
    # end

    newparam(:tags, :array_matching => :all) do
      defaultto([0,0])
      desc "Array of 802.1q tag for ends."
      #
      validate do |val|
        if !val.is_a?(Array) or val.size() != 2
          fail("Must be an array of two integers")
        end
        for i in val
          if !i.is_a?(Integer) or (i < 0 or i > 4094)
            fail("Wrong 802.1q tag. Tag must be an integer in 2..4094 interval")
          end
        end
      end
    end

    newparam(:trunks, :array_matching => :all) do
      defaultto([])
      desc "Array of trunks id, for configure patch's ends as ports in trunk mode"
      #
      validate do |val|
        val = Array(val)  # prevents puppet conversion array of one Int to Int
        for i in val
          if !i.is_a?(Integer) or (i < 0 or i > 4094)
            fail("Wrong 802.1q tag. Tag must be an integer in 2..4094 interval")
          end
        end
      end
      munge do |val|
        Array(val)
      end
    end

    autorequire(:l2_ovs_bridge) do
      self[:bridges]
    end
end
