require 'spec_helper'
require 'shared-examples'
manifest = 'master/nailgun-only.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :file
    MockFunction.new(:file) do |function|
      allow(function).to receive(:call).with(['/root/.ssh/id_rsa.pub']).and_return('key')
    end
  end

  test_ubuntu_and_centos manifest
end

