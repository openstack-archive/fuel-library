require 'spec_helper'
describe 'swift::ringbuilder::create' do

  let :default_params do
    {:part_power => 18,
    :replicas => 3,
    :min_part_hours => 24}
  end

  describe 'with allowed titles' do
    ['object', 'container', 'account'].each do |type|
      describe "when title is #{type}" do
        let :title do
          type
        end

        [{},
          {:part_power => 19,
          :replicas => 6,
          :min_part_hours => 2}].each do |param_set|

          describe "when #{param_set == {} ? "using default" : "specifying"} class parame
      ters" do
            let :param_hash do
              default_params.merge(param_set)
            end

            let :params do
              param_set
            end

            it { should contain_exec("create_#{type}").with(
              {:command => "swift-ring-builder /etc/swift/#{type}.builder create #{param_hash[:part_power]} #{param_hash[:replicas]} #{param_hash[:min_part_hours]}",
               :path    => '/usr/bin',
               :creates => "/etc/swift/#{type}.builder" }
            )}
          end
        end
      end
    end
  end
  describe 'with an invalid title' do
    let :title do
      'invalid'
    end
    it 'should raise an error' do
      expect { subject }.to raise_error(Puppet::Error)
    end
  end

end
