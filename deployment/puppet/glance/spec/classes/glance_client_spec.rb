require 'spec_helper'

describe 'glance::client' do 
  it { should contain_package('python-glance').with_ensure('present') }
end
