require 'spec_helper'

describe Puppet::Type.type(:pcmk_colocation).provider(:ruby) do

  let(:resource) { Puppet::Type.type(:pcmk_colocation).new(
      :name => 'my_colocation',
      :provider => :ruby,
      :primitives => %w(foo bar)
  ) }
  let(:provider) do
    provider = resource.provider
    if ENV['SPEC_PUPPET_DEBUG']
      class << provider
        def debug(str)
          puts str
        end
      end
    end
    provider.stubs(:cluster_debug_report).returns(true)
    provider
  end

  describe '#create' do
    it 'should create colocation with corresponding members' do
      resource[:primitives] = %w(p_1 p_2)
      resource[:score] = 'inf'

      provider.expects(:cibadmin_apply_patch).with(<<-eos
<diff>
  <diff-added>
    <cib>
      <configuration>
        <constraints>
          <rsc_colocation __crm_diff_marker__='added:top' id='my_colocation' rsc='p_1' score='INFINITY' with-rsc='p_2'/>
        </constraints>
      </configuration>
    </cib>
  </diff-added>
</diff>
      eos
      )
      provider.create
      provider.flush
    end
  end

  describe '#destroy' do
    it 'should destroy colocation with corresponding name' do
      provider.expects(:cibadmin_remove).with("<rsc_colocation id='my_colocation'/>")
      provider.destroy
      provider.flush
    end
  end


end

