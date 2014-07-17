require 'spec_helper_acceptance'

if hosts.length == 1
  describe "running puppet" do
    it 'should be able to apply class haproxy' do
      pp = <<-EOS
      class { 'haproxy': }
      haproxy::listen { 'test00': ports => '80',}
      EOS
      apply_manifest(pp, :catch_failures => true)
    end
  end
end
