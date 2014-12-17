puppet-boolean
==============

Define actual boolean parameters and properties for puppet types.

Synopsis
--------

Puppet has loosely defined internal types which can make normalizing boolean
values in types and providers difficult. This custom parameter and property
will handle that normalization in one place by defining actual boolean states.

Example
-------

**Type implementation**:

    require 'puppet/property/boolean'

    Puppet::Type.newtype(:awesome) do

      newparam(:name, :namevar => true)

      newparam(:more_explosions, :parent => Puppet::Parameter::Boolean) do
        desc "Indicate that more explosions are neccessary"
        defaultto true # When it doubt, we want more explosions
      end

      newproperty(:better_than_sliced_bread, :parent => Puppet::Property::Boolean) do
        desc "Determine if the thing is more awesome than sliced bread"
        defaultto true # It's not hard to be more awesome than sliced bread
      end

      newproperty(:better_than_rocket_boots, :parent => Puppet::Property::Boolean) do
        desc "Determine if the thing is more often than rocket boots"
        defaultto false # Rocket boots are pretty hard to beat
      end

      newproperty(:will_get_you_eaten_by_sharks, :parent => Puppet::Property::Boolean) do
        desc "Determine if this is so awesome that it'll get you eaten by sharks"
        defaultto :false # Use a symbol for the default value and it'll still be false
      end

      newproperty(:suitable_for_human_consumption, :parent => Puppet::Property::Boolean) do
        desc "Determine if the thing is both awesome and edible"
        defaultto :false # The are more non-edible things than edible things
      end
    end

**Type usage**:

    awesome { 'actual booleans':
      more_explosions                => 'yes',  # Use yes as a quoted string!
      better_than_rocket_boots       => true,   # Use an unquoted string!
      better_than_sliced_bread       => 'true', # Use a quoted string!
      suitable_for_human_consumption => no,     # Use yes and no! It doesn't matter!
    }

Contact
-------

  * source code: https://github.com/adrienthebo/puppet-boolean
  * issue tracker: https://github.com/adrienthebo/puppet-boolean/issues

If you have questions or concerns about this module, contact finch on #puppet
on Freenode, or email adrien@puppetlabs.com.
