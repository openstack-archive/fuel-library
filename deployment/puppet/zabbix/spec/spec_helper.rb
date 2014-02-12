require 'rubygems'
require 'rspec-hiera-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.filter_run_excluding :broken => true
end

shared_context "hieradata" do
  let(:hiera_config) do
    { :backends => ['rspec', 'json'],
      :hierarchy => [
        "operatingsystem/%{operatingsystem}",
        "osfamily/%{osfamily}",
        "common"],
      :rspec => respond_to?(:hiera_data) ? hiera_data : {} }
  end
end
