require 'spec_helper'

describe 'default_provider_for' do
  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params('file').and_return('posix') }
end