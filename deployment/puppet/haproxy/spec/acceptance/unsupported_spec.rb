require 'spec_helper_acceptance'

# C9710 C9711
describe 'unsupported distributions and OSes', :if => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  it 'should fail' do
    pp = <<-EOS
      class { 'haproxy': }
    EOS
    expect(apply_manifest(pp, :expect_failures => true).stderr).to match(/not supported/i)
  end
end
