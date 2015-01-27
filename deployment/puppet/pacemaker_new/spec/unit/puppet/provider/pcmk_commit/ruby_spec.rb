require 'spec_helper'

describe Puppet::Type.type(:pcmk_commit).provider(:ruby) do

  let(:resource) { Puppet::Type.type(:pcmk_commit).new(
      :name => 'my_cib',
      :provider => :ruby,
    )
  }
  let(:provider) do
    provider = resource.provider
    if ENV['SPEC_PUPPET_DEBUG']
      class << provider
        def debug(str)
          puts str
        end
      end
    end
    provider
  end

  describe '#commit' do
    it 'should commit corresponding cib' do
      provider.stubs(:wait_for_online).returns(true)
      provider.expects(:crm_shadow).with('--force', '--commit', 'my_cib').returns(true)
      provider.sync 'my_cib'
    end
  end

end

