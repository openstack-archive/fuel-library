#!/usr/bin/env bash
set -eu

# Avoid Psych bug in Ruby 1.9.3p0 on Ubuntu 12.04
export RBENV_VERSION="1.9.3"

rm -f Gemfile.lock
bundle install --path "${HOME}/bundles/${JOB_NAME}" --shebang ruby
bundle exec rake
bundle exec rake publish_gem
