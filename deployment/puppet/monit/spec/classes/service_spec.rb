require 'spec_helper'

describe 'monit::service' do
  it { should contain_service('monit') }
end
