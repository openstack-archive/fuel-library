#!/bin/sh
DIR=`dirname $0`
cd "${DIR}" || exit 1
rspec spec/hosts/*_spec.rb
rspec spec/hosts/*/*_spec.rb
