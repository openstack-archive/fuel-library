require 'spec_helper'

describe 'sanitize_bool_in_hash' do

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should convert string-boolean values to boolean' do
    is_expected.to run.with_params(
        {
            :s_true => 'true',
            :s_false => 'false',
            :s_none => 'none',
            :s_null => 'null',
            :s_nil => 'nil',
            :s_nill => 'nill',
        }
    ).and_return(
        {
            :s_true => true,
            :s_false => false,
            :s_none => nil,
            :s_null => nil,
            :s_nil => nil,
            :s_nill => nil,
        }
    )
  end

  it 'should convert UP-sace string-boolean values to boolean' do
    is_expected.to run.with_params(
        {
            :s_true => 'TRUE',
            :s_false => 'FALSE',
            :s_none => 'NONE',
            :s_null => 'NULL',
            :s_nil => 'NIL',
            :s_nill => 'NILL',
        }
    ).and_return(
        {
            :s_true => true,
            :s_false => false,
            :s_none => nil,
            :s_null => nil,
            :s_nil => nil,
            :s_nill => nil,
        }
    )
  end

  it 'should convert recursive hashes' do
    #TODO: boolean values in arrays are not sanitized correctly, it should be fixed
    #TODO: this function should somehow support ":undef" values at Puppet4
    is_expected.to run.with_params(
        {
            :bool_hash1 => {
                :str => 'aaa',
                :int => 123,
                :array => [111, 222, 333],
                :hash => {
                    :str => 'aaa',
                    :int => 123,
                    :array => [111, 222, 333],
                    #:a_sbool => ['true', 'nil', 'false'],
                    :a_bool => [true, nil, false],
                    :hash => {
                        :str => 'aaa',
                        :int => 123,
                        :array => [111, 222, 333],
                        #:a_sbool => ['true', 'nil', 'false'],
                        :a_bool => [true, nil, false],
                    },
                },
                #:a_sbool => ['true', 'nil', 'false'],
                :a_bool => [true, nil, false],
            },
            :bool_hash2 => {
                :t => true,
                :f => false,
                :n => nil
            },
        }
    ).and_return(
        {
            :bool_hash1 => {
                :str => 'aaa',
                :int => 123,
                :array => [111, 222, 333],
                :hash => {
                    :str => 'aaa',
                    :int => 123,
                    :array => [111, 222, 333],
                    #:a_sbool => [true, nil, false],
                    :a_bool => [true, nil, false],
                    :hash => {
                        :str => 'aaa',
                        :int => 123,
                        :array => [111, 222, 333],
                        #:a_sbool => [true, nil, false],
                        :a_bool => [true, nil, false],
                    },
                },
                #:a_sbool => [true, nil, false],
                :a_bool => [true, nil, false],
            },
            :bool_hash2 => {
                :t => true,
                :f => false,
                :n => nil
            },
        }
    )
  end

  it 'should convert array of hashes' do
    is_expected.to run.with_params(
        {
            :array => [
                {:aaa => 1, "aaa" => 11, :bbb => 2, 'bbb' => 12, :ccc => 3, 'ccc' => 3},
                {:t => 'true', 'tt' => 'true', :f => 'false', 'ff' => 'false', :n => 'nil', 'nn' => 'nil'},
                {
                    :s_true => 'true',
                    :s_false => 'false',
                    :s_none => 'none',
                    :s_null => 'null',
                    :s_nil => 'nil',
                    :s_nill => 'nill',
                },
                {
                    :s_true => 'TRUE',
                    :s_false => 'FALSE',
                    :s_none => 'NONE',
                    :s_null => 'NULL',
                    :s_nil => 'NIL',
                    :s_nill => 'NILL',
                },
            ]
        }
    ).and_return(
        {
            :array => [
                {:aaa => 1, "aaa" => 11, :bbb => 2, 'bbb' => 12, :ccc => 3, 'ccc' => 3},
                {:t => true, 'tt' => true, :f => false, 'ff' => false, :n => nil, 'nn' => nil},
                {
                    :s_true => true,
                    :s_false => false,
                    :s_none => nil,
                    :s_null => nil,
                    :s_nil => nil,
                    :s_nill => nil,
                },
                {
                    :s_true => true,
                    :s_false => false,
                    :s_none => nil,
                    :s_null => nil,
                    :s_nil => nil,
                    :s_nill => nil,
                },
            ]
        }
    )
  end

  it 'should throw an error' do
    is_expected.to run.with_params('xxx').and_raise_error(Puppet::ParseError)
  end

end
