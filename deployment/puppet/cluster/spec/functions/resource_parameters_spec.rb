require 'spec_helper'

describe 'resource_parameters' do
  it { is_expected.not_to eq(nil) }

  it { is_expected.to run.with_params.and_return({}) }

  it { is_expected.to run.with_params(nil).and_return({}) }

  it { is_expected.to run.with_params(false).and_return({}) }

  it { is_expected.to run.with_params(nil, 'b').and_return({}) }

  it { is_expected.to run.with_params('a').and_return({}) }

  it { is_expected.to run.with_params('a', 'b').and_return({'a' => 'b'}) }

  it { is_expected.to run.with_params('a', 'b', 'c', nil, ['d', 1], 'e', :undef).and_return({'a' => 'b', 'd' => 1}) }

  it { is_expected.to run.with_params('a', 'b', 'c', 'd', {'e' => 'f', 'a' => '10'}).and_return({'a' => '10', 'c' => 'd', 'e' => 'f'}) }
end
