require 'spec_helper_system'

describe 'mongodb class' do

  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      pp = <<-EOS
      class { 'mongodb': }
      EOS

      # Run it twice and test for idempotency
      puppet_apply(pp) do |r|
        r.exit_code.should eq 2
        r.refresh
        r.exit_code.should be_zero
      end
    end
  end
end
