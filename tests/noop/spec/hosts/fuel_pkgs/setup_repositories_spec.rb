require 'spec_helper'
require 'shared-examples'
manifest = 'fuel_pkgs/setup_repositories.pp'

describe manifest do
  before(:each) do
    Noop.puppet_function_load :generate_apt_pins
    MockFunction.new(:generate_apt_pins) do |function|
      allow(function).to receive(:call).and_return({})
    end
  end

  test_ubuntu_and_centos manifest
end

