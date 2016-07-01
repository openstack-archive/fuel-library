require 'spec_helper'

describe 'default_provider_for' do

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.not_to be_nil }

      it { is_expected.to run.with_params('file').and_return('posix') }

    end
  end

end
