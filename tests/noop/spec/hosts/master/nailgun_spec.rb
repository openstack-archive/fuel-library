require 'spec_helper'
require 'shared-examples'
manifest = 'master/nailgun.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  before(:each) do
    Noop.puppet_function_load :file
    MockFunction.new(:file) do |function|
      allow(function).to receive(:call).with(['/root/.ssh/id_rsa.pub']).and_return('key')
    end
  end

  run_test manifest
end
