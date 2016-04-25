require 'spec_helper'

describe 'format_allocation_pools' do

  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params().and_raise_error(ArgumentError, /Wrong number of arguments given/) }
  it { is_expected.to run.with_params('10.109.1.1:')and_raise_error(ArgumentError, /Requires array\/string/) }

  it { is_expected.to run.with_params(
      [
        '10.109.1.151:10.109.1.254',
        '10.109.1.130:10.109.1.150'
      ],
      "10.109.1.0/24"
    ).and_return(
      [
        'start=10.109.1.151,end=10.109.1.254',
        'start=10.109.1.130,end=10.109.1.150'
      ]
  )}

  it { is_expected.to run.with_params(
      [
        '10.109.1.151:10.109.1.254',
        '10.109.1.130:10.109.1.150'
    ]).and_return(
      [
        'start=10.109.1.151,end=10.109.1.254',
        'start=10.109.1.130,end=10.109.1.150'
      ]
  )}

  it { is_expected.to run.with_params(
      '10.109.1.133:10.109.1.169', '10.109.1.0/24'
    ).and_return(['start=10.109.1.133,end=10.109.1.169'])
  }

  it { is_expected.to run.with_params(
      [
        '10.109.1.151:10.109.1.254',
        '10.110.1.130:10.110.1.150'
      ],
      '10.109.1.0/24'
    ).and_return(['start=10.109.1.151,end=10.109.1.254'])
  }

end
