# This adds upfront requirements on vendored code found under lib/vendor/x
# Add one requirement per vendored package (or a comment if it is loaded on demand).

require 'safe_yaml'
require 'puppet/vendor/safe_yaml_patches'
