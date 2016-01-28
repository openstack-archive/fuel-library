require 'spec_helper'

describe 'override_resources' do

  let(:override_configuration) do
    {
      'nova_config' => {
        'DEFAULT/debug' => 'True',
        'DEFAULT/verbose' => 'False',
      },
      'neutron_config' => {
        'DEFAULT/bind_port' => 1010
      }
    }
  end


  context 'when wrong data provided' do
    it 'should exist' do
      is_expected.not_to eq(nil)
    end

    it 'should fail if first argument is empty' do
      is_expected.to run.with_params('', override_configuration['nova_config']).and_raise_error(Puppet::Error, /First argument should be/)
    end

    it 'should fail if second argument is not hash' do
      is_expected.to run.with_params('nova_config', "test").and_raise_error(Puppet::Error, /Second arguments should contain/)
    end

    it 'should fail if third argument is not hash' do
      is_expected.to run.with_params('nova_config', override_configuration['nova_config'], "test").and_raise_error(Puppet::Error, /Third arguments should contain/)
    end
  end

  context 'when good data provided' do
    it 'should pass when second argument is nil or empty' do
      is_expected.to run.with_params('nova_config', nil).and_return({})
      is_expected.to run.with_params('nova_config', "").and_return({})
    end

  end

end
