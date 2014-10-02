require 'spec_helper'

describe 'monit::config' do
  it { should contain_file('/etc/monit/monitrc') }
end
