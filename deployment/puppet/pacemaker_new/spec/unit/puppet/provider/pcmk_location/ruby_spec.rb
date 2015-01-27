require 'spec_helper'

describe Puppet::Type.type(:pcmk_location).provider(:ruby) do

  def make_resource(params = {})
    params = {
        :name => 'my_location',
        :provider => :ruby,
        :primitive => 'my_primitive',
    }.merge params

    Puppet::Type.type(:pcmk_location).new params
  end

  def make_provider(params = {}, debug = false)
    resource = make_resource params
    provider = resource.provider
    fail 'Could not get the provider!' unless provider
    provider.stubs(:cluster_debug_report).returns(true)
    return provider unless debug
    #class << provider
    #  def debug(msg)
    #    puts msg
    #  end
    #
    #  def cibadmin_apply_patch(xml)
    #    debug "Apply XML patch:\n#{xml}"
    #  end
    #
    #  def cibadmin_remove(xml)
    #    debug "Remove XML section:\n#{xml}"
    #  end
    #end
    provider
  end

  describe '#create' do

    it 'should create a simple location' do
      params = {
          :node_name => 'my_node',
          :node_score => '200',
      }
      provider = make_provider params
      provider.expects(:cibadmin_apply_patch).with(<<-eos
<diff>
  <diff-added>
    <cib>
      <configuration>
        <constraints>
          <rsc_location id='my_location' node='my_node' rsc='my_primitive' score='200'/>
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

    it 'should create location with rule' do
      provider = make_provider(
          {
              :rules => [
                  {
                      :score => 'inf',
                      :expressions => [
                          {
                              :attribute => 'pingd1',
                              :operation => 'defined',
                          },
                          {
                              :attribute => 'pingd2',
                              :operation => 'defined',
                          }
                      ]
                  }
              ]
          })

      provider.expects(:cibadmin_apply_patch).with(<<-eos
<diff>
  <diff-added>
    <cib>
      <configuration>
        <constraints>
          <rsc_location id='my_location' rsc='my_primitive'>
            <rule boolean-op='or' id='my_location-rule-0' score='INFINITY'>
              <expression attribute='pingd1' id='my_location-rule-0-expression-0' operation='defined'/>
              <expression attribute='pingd2' id='my_location-rule-0-expression-1' operation='defined'/>
            </rule>
          </rsc_location>
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

    it 'should create location with several rules' do
      provider = make_provider(
          {
              :rules => [
                  {
                      :score => 'inf',
                      :expressions => [
                          {
                              :attribute => 'pingd1',
                              :operation => 'defined',
                          }
                      ]
                  },
                  {
                      :score => 'inf',
                      :expressions => [
                          {
                              :attribute => 'pingd2',
                              :operation => 'defined',
                          }
                      ]
                  }
              ]
          })
      provider.expects(:cibadmin_apply_patch).with(<<-eos
<diff>
  <diff-added>
    <cib>
      <configuration>
        <constraints>
          <rsc_location id='my_location' rsc='my_primitive'>
            <rule boolean-op='or' id='my_location-rule-0' score='INFINITY'>
              <expression attribute='pingd1' id='my_location-rule-0-expression-0' operation='defined'/>
            </rule>
            <rule boolean-op='or' id='my_location-rule-1' score='INFINITY'>
              <expression attribute='pingd2' id='my_location-rule-1-expression-0' operation='defined'/>
            </rule>
          </rsc_location>
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

  context '#exists' do
    it 'detects an existing location' do
      params = {
          :node_name => 'my_node',
          :node_score => '200',
      }
      provider = make_provider params
      provider.stubs(:constraint_locations).returns(
          {
              'my_location' => {
                  'rsc' => 'my_resource',
                  'node' => 'my_node',
                  'score' => '100',
              }
          }
      )
      expect(provider.exists?).to be_truthy
      provider.stubs(:constraint_locations).returns(
          {
              'other_location' => {
                  'rsc' => 'other_resource',
                  'node' => 'other_node',
                  'score' => '100',
              }
          }
      )
      expect(provider.exists?).to be_falsey
      provider.stubs(:constraint_locations).returns({})
      expect(provider.exists?).to be_falsey
    end

    it 'loads the current resource state' do
      params = {
          :node_name => 'my_node',
          :node_score => '200',
      }
      provider = make_provider params
      provider.stubs(:constraint_locations).returns(
          {
              'my_location' => {
                  'rsc' => 'my_resource',
                  'node' => 'my_node',
                  'score' => '100',
              }
          }
      )
      provider.exists?
      expect(provider.primitive).to eq('my_resource')
      expect(provider.node_name).to eq('my_node')
      expect(provider.node_score).to eq('100')
    end

  end

  context '#destroy' do
    it 'can remove a location' do
      params = {
          :node_name => 'my_node',
          :node_score => '200',
      }
      provider = make_provider params
      provider.expects(:cibadmin_remove).with("<rsc_location id='my_location'/>")
      provider.destroy
    end
  end
end

