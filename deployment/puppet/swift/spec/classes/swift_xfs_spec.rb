require 'spec_helper'
describe 'swift::xfs' do
  ['xfsprogs', 'parted'].each do |present_package|
    it { is_expected.to contain_package(present_package).with_ensure('present') }
  end
end
