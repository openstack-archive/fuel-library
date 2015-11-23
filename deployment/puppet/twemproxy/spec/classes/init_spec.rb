require 'spec_helper'
describe 'twemproxy' do

  context 'with defaults for all parameters' do
    it { should contain_class('twemproxy') }
  end
end
