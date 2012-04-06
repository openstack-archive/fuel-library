require 'spec_helper'

describe 'nova::client' do
  it { should contain_package('python-novaclient').with_ensure('present') }
end
