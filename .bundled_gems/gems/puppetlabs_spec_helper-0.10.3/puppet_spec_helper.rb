$:.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))

require 'puppetlabs_spec_helper/puppet_spec_helper'

puts "Using 'PROJECT_ROOT/puppet_spec_helper' is deprecated, please install as a gem and require 'puppetlabs_spec_helper/puppet_spec_helper' instead"
