Puppet::Type.newtype(:l2_ovs_patch) do
    @doc = "Manage a Open vSwitch patch between two bridges"
    desc @doc

    ensurable

    newparam(:name) # workarround for following error:
    # Error 400 on SERVER: Could not render to pson: undefined method `merge' for []:Array
    # http://projects.puppetlabs.com/issues/5220

    newparam(:bridges) do
      desc "Array of bridges that will be connected"
      #
      validate do |val|
        if not (val.is_a?(Array) and val.size() == 2)
          fail("Must be an array of two bridge names")
        end
        if not (val[0].is_a?(String) and val[1].is_a?(String))
          fail("Bridge names must have be a string.")
        end
      end
    end

    newparam(:peers) do
      defaultto([nil,nil])
      desc "List of names that will be used for naming patches at it's ends."
      #
      validate do |val|
        if not (val.is_a?(Array) and val.size() == 2)
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

    newparam(:tags) do
      defaultto([0,0])
      desc "Array of 802.1q tag for ends."
      #
      validate do |val|
        if not (val.is_a?(Array) and val.size() == 2)
          fail("Must be an array of integers")
        end
        for i in val
          if not i.is_a?(Integer)
            fail("802.1q tags must have be a integer.")
          end
          if i < 0 or i > 4094
            fail("Wrong 802.1q tag. Tag must be an integer in 2..4094 interval")
          end
        end
      end
    end

    newparam(:trunks) do
      defaultto([])
      desc "Array of trunks id, for configure patch's ends as ports in trunk mode"
      #
      validate do |val|
        if not (val.is_a?(Array) or val.is_a?(Integer)) # Integer need for array with one element. it's a puppet's feature
          fail("Must be an array (not #{val.class}).")
        end
        if val.is_a?(Array)
          for i in val
            if not (i.to_i >= 0 and i.to_i <= 4094)
              fail("Wrong trunk. Tag must be an integer in 2..4094 interval")
            end
          end
        else
          if not (val >= 0 and val <= 4094)
            fail("Wrong trunk. Tag must be an integer in 2..4094 interval")
          end
        end
      end
      #
      munge do |val|
        if val.is_a?(Integer)
          [val]
        else
          val
        end
      end
    end

    autorequire(:l2_ovs_bridge) do
      self[:bridges]
    end
end
