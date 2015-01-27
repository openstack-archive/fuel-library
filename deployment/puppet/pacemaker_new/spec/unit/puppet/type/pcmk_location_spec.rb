require 'spec_helper'

describe Puppet::Type.type(:pcmk_location) do

  subject do
    Puppet::Type.type(:pcmk_location)
  end

  it 'should have a "name" parameter' do
    expect(
        subject.new(
            :name => 'mock_resource',
            :node_name => 'node',
            :node_score => '100',
            :primitive => 'my_primitive'
        )[:name]
    ).to eq('mock_resource')
  end

  context 'basic structure' do
    it 'should be able to create an instance' do
      expect(
          subject.new(
              :name => 'mock_resource',
              :node_name => 'node',
              :node_score => '100',
              :primitive => 'my_primitive'
          )
      ).to_not be_nil
    end

    [:cib, :name].each do |param|
      it "should have a #{param} parameter" do
        expect(subject.validparameter?(param)).to be_truthy
      end

      it "should have documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_a(String)
      end
    end

    [:primitive, :node_score, :rules, :node_name].each do |property|
      it "should have a #{property} property" do
        expect(subject.validproperty?(property)).to be_truthy
      end
      it "should have documentation for its #{property} property" do
        expect(subject.propertybyname(property).doc).to be_a(String)
      end
    end

  end

  context 'validation and munging' do

    context 'node_score' do
      it 'should allow only correct node_score values' do
        expect {
          subject.new(
              :name => 'mock_resource',
              :primitive => 'my_primitive',
              :node_name => 'node',
              :node_score => 'test'
          )
        }.to raise_error
        expect(subject.new(
                   :name => 'mock_resource',
                   :primitive => 'my_primitive',
                   :node_name => 'node',
                   :node_score => '100'
               )).to_not be_nil
        expect(subject.new(
                   :name => 'mock_resource',
                   :primitive => 'my_primitive',
                   :node_name => 'node',
                   :node_score => 'inf'
               )).to_not be_nil
      end

      it 'should change inf to INFINITY' do
        expect(
            subject.new(
                :name => 'mock_resource',
                :primitive => 'my_primitive',
                :node_name => 'node',
                :node_score => 'inf'
            )[:node_score]
        ).to eq 'INFINITY'
        expect(
            subject.new(
                :name => 'mock_resource',
                :primitive => 'my_primitive',
                :node_name => 'node',
                :node_score => '-inf'
            )[:node_score]
        ).to eq '-INFINITY'
      end
    end

    context 'rules' do
      it 'should stringify keys and values' do
        expect(
            subject.new(
                :name => 'mock_resource',
                :primitive => 'my_primitive',
                :rules => {
                    'id' => 'test',
                    'boolean-op' => :or,
                    :a => 1,
                    2 => :c
                }
            )[:rules].first
        ).to eq({
                    'boolean-op' => 'or',
                    'id' => 'test',
                    '2' => 'c',
                    'a' => '1'
                })
      end
      it 'should generate missing rule id' do
        expect(
            subject.new(
                :name => 'mock_resource',
                :primitive => 'my_primitive',
                :rules => {
                    'a' => '1',
                    'boolean-op' => 'or'
                }
            )[:rules].first
        ).to eq({
                    'boolean-op' => 'or',
                    'id' => 'mock_resource-rule-0',
                    'a' => '1'
                })
      end
      it 'should add missing boolean-op' do
        expect(
            subject.new(
                :name => 'mock_resource',
                :primitive => 'my_primitive',
                :rules => {
                    'id' => 'test'
                }
            )[:rules].first
        ).to eq({
                    'boolean-op' => 'or',
                    'id' => 'test'
                })
      end
      it 'should change rule score from inf to INFINITY' do
        expect(
            subject.new(
                :name => 'mock_resource',
                :primitive => 'my_primitive',
                :rules => {
                    'id' => 'test',
                    'boolean-op' => 'and',
                    'score' => 'inf'
                }
            )[:rules].first
        ).to eq({
                    'boolean-op' => 'and',
                    'id' => 'test',
                    'score' => 'INFINITY'
                })
      end
      it 'should generate missing expression id' do
        expect(
            subject.new(
                :name => 'mock_resource',
                :primitive => 'my_primitive',
                :rules => {
                    :score => 'inf',
                    :id => 'test',
                    :expressions => [
                        {
                            :attribute => 'pingd1',
                            :operation => 'defined',
                            :id => 'first_expression',
                        },
                        {
                            :attribute => 'pingd2',
                            :operation => 'defined',
                        }
                    ]
                }
            )[:rules].first
        ).to eq({'score' => 'INFINITY', 'id' => 'test', 'boolean-op' => 'or',
                 'expressions' => [
                     {
                         'operation' => 'defined',
                         'attribute' => 'pingd1',
                         'id' => 'first_expression',
                     },
                     {
                         'operation' => 'defined',
                         'attribute' => 'pingd2',
                         'id' => 'mock_resource-rule-0-expression-1',
                     }
                 ]
                })
      end
    end
  end

  describe 'when autorequiring resources' do
    before :each do
      @pcmk_resource = Puppet::Type.type(:pcmk_resource).new(
          :name => 'foo',
          :ensure => :present
      )
      @pcmk_shadow = Puppet::Type.type(:pcmk_shadow).new(
          :name => 'baz',
          :cib => 'baz'
      )
      @catalog = Puppet::Resource::Catalog.new
      @catalog.add_resource @pcmk_shadow, @pcmk_resource
    end

    it 'should autorequire the corresponding resources' do
      @resource = described_class.new(
          :name => 'mock_resource',
          :primitive => 'foo',
          :node_name => 'node',
          :node_score => '100',
          :cib => 'baz'
      )
      @catalog.add_resource @resource
      required_resources = @resource.autorequire
      expect(required_resources.size).to eq 2
      required_resources.each do |e|
        expect(e.target).to eq(@resource)
        expect([@pcmk_resource, @pcmk_shadow]).to include e.source
      end
    end
  end


end
