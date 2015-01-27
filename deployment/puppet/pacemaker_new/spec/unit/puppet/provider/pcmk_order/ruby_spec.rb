require 'spec_helper'

describe Puppet::Type.type(:pcmk_order).provider(:ruby) do

  let(:resource) { Puppet::Type.type(:pcmk_order).new(
      :name => 'my_order',
      :provider => :ruby,
      :first => 'p_1',
      :second => 'p_2'
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
    it 'should create order with corresponding members' do
      resource[:first] = 'p_1'
      resource[:second] ='p_2'
      resource[:score] = 'inf'
      provider.expects(:cibadmin_apply_patch).with(<<-eos
<diff>
  <diff-added>
    <cib>
      <configuration>
        <constraints>
          <rsc_order __crm_diff_marker__='added:top' first='p_1' id='my_order' score='INFINITY' then='p_2'/>
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
    it 'should destroy order with corresponding name' do
      provider.expects(:cibadmin_remove).with("<rsc_order id='my_order'/>")
      provider.destroy
      provider.flush
    end
  end

end

