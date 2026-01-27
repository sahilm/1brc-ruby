#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "stackprof"
require_relative "./v1_1brc"

StackProf.run(mode: :cpu, raw: true, out: "tmp/stackprof.dump") do
  puts V1::OneBRC.compute
end
