require 'spec_helper'

describe 'undef2nil' do

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should not modify normal values' do
    is_expected.to run.with_params('test').and_return('test')
    is_expected.to run.with_params(nil).and_return(nil)
  end

  it 'should change :undef to nil in a simple value' do
    is_expected.to run.with_params(:undef).and_return(nil)
  end

  it 'should be able to process arrays' do
    is_expected.to run.with_params(['1', 2, :undef, nil, {}, [1]]).and_return(['1', 2, nil, nil, {}, [1]])
  end

  it 'should be able to process hashes' do
    is_expected.to run.with_params(
        {
            'a' => 'b',
            'c' => ['d'],
            'e' => :undef,
            :undef => 'f',
            'g' => {
                'a' => :undef,
                'b' => [1, :undef],
            }
        }
    ).and_return(
        {
            'a' => 'b',
            'c' => ['d'],
            'e' => nil,
            :undef => 'f',
            'g' => {
                'a' => nil,
                'b' => [1, nil],
            }
        }
    )
  end

end
