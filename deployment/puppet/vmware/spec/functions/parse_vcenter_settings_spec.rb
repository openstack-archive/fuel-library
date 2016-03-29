require 'spec_helper'

describe 'parse_vcenter_settings', :type => :puppet_function do
  it { is_expected.to run.with_params().and_raise_error(ArgumentError) }

  it { is_expected.to run.with_params([]).and_return({}) }
  it { is_expected.to run.with_params('').and_return({}) }
  it { is_expected.to run.with_params(1).and_return({}) }
  it { is_expected.to run.with_params(nil).and_return({}) }

  it { is_expected.to run.with_params(
      {
          'a' => '1',
      }
  ).and_return(
      {
          '0' => {
              'a' => '1',
          }
      }
  ) }
  it { is_expected.to run.with_params(
      [
          {
              'a' => '1',
          },
          {
              'a' => '2',
              'b' => '3',
          },
      ]
  ).and_return(
      {
          '0' => {
              'a' => '1',
          },
          '1' => {
              'a' => '2',
              'b' => '3',
          }
      }
  ) }
end
