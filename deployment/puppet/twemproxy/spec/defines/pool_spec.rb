require 'spec_helper'

describe 'twemproxy::pool' do

  let(:title) { 'default' }

  let :facts do
    {
      # I hate doing such shit
      :concat_basedir => '/tmp'
    }
  end

  let(:default_params) { {:clients_array => [
                                     '10.10.10.10:11211:1',
                                     '10.10.10.20:11211:1',
                                    ],
               } }

  context 'with defaults for all parameters' do

    let :params do
      default_params
    end

    it "should contain twemproxy::listen" do
      should contain_twemproxy__listen('default')
    end

    it "should contain twemproxy::member" do
      should contain_twemproxy__member('default')
    end

  end

end
