require 'spec_helper'

describe 'monit::package' do
  it { should contain_package('monit') }
end
