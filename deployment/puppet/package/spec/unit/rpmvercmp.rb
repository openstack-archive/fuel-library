require 'spec_helper'
require File.dirname(__FILE__) + '/../../lib/puppet/provider/package/rpmvercmp.rb'

cases = [
    [1,2],
    [2,1,1],
    [1,1,0],
    ['','a'],
    [nil,'a'],
    [nil,nil,0],
    ['a','1'],
    ['a1','ab'],
    ['a.a','a.1'],
    ['1.1.1-1','1.1.1-2'],
    ['1.1.1','1.1.2'],
    ['1.1.1','1.1.1-1'],
    ['1.1.1','1:1.1.1'],
    ['0:2.3.4','1:1'],
    ['1.1-asd1','1.1.1-asd2'],
    ['1.2-3', '1.2.3'],
    ['1.1','1.~1'],
    ['1.2.3-r1', '1.2-fuel1-r1'],
    ['2.fuel1', '1.fuel2'],
    ['1.2.3-fuel1.1-r1', '1.2-fuel2.0-r2'],
]

describe Rpmvercmp do
  cases.each do |c|
    c << -1 unless c[2]
    it "#{c[0]} vs #{c[1]} -> #{c[2]}" do
      rc = Rpmvercmp.compare_labels c[0], c[1]
      expect(rc).to eq(c[2])
    end
  end
end