# require 'puppet'
# require 'rspec'
# require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'
begin
  require 'puppet/parser/functions/lib/l23network_scheme.rb'
rescue LoadError => e
  # puppet apply does not add module lib directories to the $LOAD_PATH (See
  # #4248). It should (in the future) but for the time being we need to be
  # defensive which is what this rescue block is doing.
  rb_file = File.join(File.dirname(__FILE__),'lib','l23network_scheme.rb')
  load rb_file if File.exists?(rb_file) or raise e
end


describe 'generate_network_config' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  # before(:each) do
  #   L23network::Scheme.set = {
  #     :endpoints => {
  #       :eth0 => {:IP => 'dhcp'},
  #       :"br-ex" => {
  #         :gateway => '10.1.3.1',
  #         :IP => ['10.1.3.11/24'],
  #       },
  #       :"br-mgmt" => { :IP => ['10.20.1.11/25'] },
  #       :"br-storage" => { :IP => ['192.168.1.2/24'] },
  #       :"br-prv" => { :IP => 'none' },
  #     },
  #     :roles => {
  #       :management => 'br-mgmt',
  #       :private => 'br-prv',
  #       :ex => 'br-ex',
  #       :storage => 'br-storage',
  #       :admin => 'eth0',
  #     },
  #   }
  # end

  it 'should exist' do
    Puppet::Parser::Functions.function('generate_network_config').should == 'function_generate_network_config'
  end

  # it 'should convert string-boolean values to boolean' do
  #   should run.with_params({
  #     :s_true  => 'true',
  #     :s_false => 'false',
  #     :s_none => 'none',
  #     :s_null => 'null',
  #     :s_nil  => 'nil',
  #     :s_nill => 'nill',
  #   }).and_return({
  #     :s_true  => true,
  #     :s_false => false,
  #     :s_none => nil,
  #     :s_null => nil,
  #     :s_nil  => nil,
  #     :s_nill => nil,
  #   })
  # end

  # it 'should convert UP-sace string-boolean values to boolean' do
  #   should run.with_params({
  #     :s_true  => 'TRUE',
  #     :s_false => 'FALSE',
  #     :s_none => 'NONE',
  #     :s_null => 'NULL',
  #     :s_nil  => 'NIL',
  #     :s_nill => 'NILL',
  #   }).and_return({
  #     :s_true  => true,
  #     :s_false => false,
  #     :s_none => nil,
  #     :s_null => nil,
  #     :s_nil  => nil,
  #     :s_nill => nil,
  #   })
  # end

  # it 'should convert reccursive hashes' do
  #   should run.with_params({
  #     :bool_hash => {
  #       :str => 'aaa',
  #       :int => 123,
  #       :array => [111,222,333],
  #       :hash => {
  #         :str => 'aaa',
  #         :int => 123,
  #         :array => [111,222,333],
  #         :a_sbool => ['true', 'nil', 'false'],
  #         :a_bool => [true, nil, false],
  #         :hash => {
  #           :str => 'aaa',
  #           :int => 123,
  #           :array => [111,222,333],
  #           :a_sbool => ['true', 'nil', 'false'],
  #           :a_bool => [true, nil, false],
  #         },
  #       },
  #       :a_sbool => ['true', 'nil', 'false'],
  #       :a_bool => [true, nil, false],
  #     },
  #     :bool_hash => {
  #       :t => true,
  #       :f => false,
  #       :n => nil
  #     },
  #   }).and_return({
  #     :bool_hash => {
  #       :str => 'aaa',
  #       :int => 123,
  #       :array => [111,222,333],
  #       :hash => {
  #         :str => 'aaa',
  #         :int => 123,
  #         :array => [111,222,333],
  #         :a_sbool => [true, nil, false],
  #         :a_bool => [true, nil, false],
  #         :hash => {
  #           :str => 'aaa',
  #           :int => 123,
  #           :array => [111,222,333],
  #           :a_sbool => [true, nil, false],
  #           :a_bool => [true, nil, false],
  #         },
  #       },
  #       :a_sbool => [true, nil, false],
  #       :a_bool => [true, nil, false],
  #     },
  #     :bool_hash => {
  #       :t => true,
  #       :f => false,
  #       :n => nil
  #     },
  #   })
  # end

  # it 'should convert array of hashes' do
  #   should run.with_params({ :array => [
  #     {:aaa=>1,"aaa"=>11, :bbb=>2,'bbb'=>12, :ccc=>3,'ccc'=>3},
  #     {:t=>'true','tt'=>'true', :f=>'false','ff'=>'false', :n=>'nil','nn'=>'nil'},
  #     {
  #       :s_true  => 'true',
  #       :s_false => 'false',
  #       :s_none => 'none',
  #       :s_null => 'null',
  #       :s_nil  => 'nil',
  #       :s_nill => 'nill',
  #     },
  #     {
  #       :s_true  => 'TRUE',
  #       :s_false => 'FALSE',
  #       :s_none => 'NONE',
  #       :s_null => 'NULL',
  #       :s_nil  => 'NIL',
  #       :s_nill => 'NILL',
  #     },
  #   ]}).and_return({ :array => [
  #     {:aaa=>1,"aaa"=>11, :bbb=>2,'bbb'=>12, :ccc=>3,'ccc'=>3},
  #     {:t=>true,'tt'=>true, :f=>false,'ff'=>false, :n=>nil,'nn'=>nil},
  #     {
  #       :s_true  => true,
  #       :s_false => false,
  #       :s_none => nil,
  #       :s_null => nil,
  #       :s_nil  => nil,
  #       :s_nill => nil,
  #     },
  #     {
  #       :s_true  => true,
  #       :s_false => false,
  #       :s_none => nil,
  #       :s_null => nil,
  #       :s_nil  => nil,
  #       :s_nill => nil,
  #     },
  #   ]})
  # end

  # it 'should throw an error' do
  #   lambda {
  #    scope.function_concat(['xxx'])
  #   }.should(raise_error(Puppet::ParseError))
  # end

end

# vim: set ts=2 sw=2 et :
