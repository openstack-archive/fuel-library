require 'spec_helper'

describe 'sanitize_bool_in_hash' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    Puppet::Parser::Functions.function('sanitize_bool_in_hash').should == 'function_sanitize_bool_in_hash'
  end

  it 'should convert string-boolean values to boolean' do
    expect(scope.function_sanitize_bool_in_hash([{
      :s_true  => 'true',
      :s_false => 'false',
      :s_none => 'none',
      :s_null => 'null',
      :s_nil  => 'nil',
      :s_nill => 'nill',
    }])).to eq({
      :s_true  => true,
      :s_false => false,
      :s_none => nil,
      :s_null => nil,
      :s_nil  => nil,
      :s_nill => nil,
    })
  end

  it 'should convert UP-sace string-boolean values to boolean' do
    expect(scope.function_sanitize_bool_in_hash([{
      :s_true  => 'TRUE',
      :s_false => 'FALSE',
      :s_none => 'NONE',
      :s_null => 'NULL',
      :s_nil  => 'NIL',
      :s_nill => 'NILL',
    }])).to eq({
      :s_true  => true,
      :s_false => false,
      :s_none => nil,
      :s_null => nil,
      :s_nil  => nil,
      :s_nill => nil,
    })
  end

  it 'should convert reccursive hashes' do
    expect(scope.function_sanitize_bool_in_hash([{
      :bool_hash => {
        :str => 'aaa',
        :int => 123,
        :array => [111,222,333],
        :hash => {
          :str => 'aaa',
          :int => 123,
          :array => [111,222,333],
          :a_sbool => ['true', 'nil', 'false'],
          :a_bool => [true, nil, false],
          :hash => {
            :str => 'aaa',
            :int => 123,
            :array => [111,222,333],
            :a_sbool => ['true', 'nil', 'false'],
            :a_bool => [true, nil, false],
          },
        },
        :a_sbool => ['true', 'nil', 'false'],
        :a_bool => [true, nil, false],
      },
      :bool_hash => {
        :t => true,
        :f => false,
        :n => nil
      },
    }])).to eq({
      :bool_hash => {
        :str => 'aaa',
        :int => 123,
        :array => [111,222,333],
        :hash => {
          :str => 'aaa',
          :int => 123,
          :array => [111,222,333],
          :a_sbool => [true, nil, false],
          :a_bool => [true, nil, false],
          :hash => {
            :str => 'aaa',
            :int => 123,
            :array => [111,222,333],
            :a_sbool => [true, nil, false],
            :a_bool => [true, nil, false],
          },
        },
        :a_sbool => [true, nil, false],
        :a_bool => [true, nil, false],
      },
      :bool_hash => {
        :t => true,
        :f => false,
        :n => nil
      },
    })
  end

  it 'should convert array of hashes' do
    expect(scope.function_sanitize_bool_in_hash([{ :array => [
      {:aaa=>1,"aaa"=>11, :bbb=>2,'bbb'=>12, :ccc=>3,'ccc'=>3},
      {:t=>'true','tt'=>'true', :f=>'false','ff'=>'false', :n=>'nil','nn'=>'nil'},
      {
        :s_true  => 'true',
        :s_false => 'false',
        :s_none => 'none',
        :s_null => 'null',
        :s_nil  => 'nil',
        :s_nill => 'nill',
      },
      {
        :s_true  => 'TRUE',
        :s_false => 'FALSE',
        :s_none => 'NONE',
        :s_null => 'NULL',
        :s_nil  => 'NIL',
        :s_nill => 'NILL',
      },
    ]}])).to eq({ :array => [
      {:aaa=>1,"aaa"=>11, :bbb=>2,'bbb'=>12, :ccc=>3,'ccc'=>3},
      {:t=>true,'tt'=>true, :f=>false,'ff'=>false, :n=>nil,'nn'=>nil},
      {
        :s_true  => true,
        :s_false => false,
        :s_none => nil,
        :s_null => nil,
        :s_nil  => nil,
        :s_nill => nil,
      },
      {
        :s_true  => true,
        :s_false => false,
        :s_none => nil,
        :s_null => nil,
        :s_nil  => nil,
        :s_nill => nil,
      },
    ]})
  end

  it 'should throw an error' do
    lambda {
     scope.function_sanitize_bool_in_hash(['xxx'])
    }.should(raise_error(Puppet::ParseError))
  end

end

# vim: set ts=2 sw=2 et :
