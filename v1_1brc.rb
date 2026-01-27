# frozen_string_literal: true

RubyVM::YJIT.enable

require "bigdecimal"

module V1
  Stats = Struct.new(:min, :max, :sum, :count) do
    def initialize
      super(Float::INFINITY, -Float::INFINITY, 0.0, 0)
    end

    def add_measurement(value)
      self.min = value if value < min
      self.max = value if value > max
      self.sum += value
      self.count += 1
    end

    def to_s
      "#{min.to_s('F')}/#{(sum / count).round(1).to_s('F')}/#{max.to_s('F')}"
    end
  end

  class OneBRC
    def self.compute
      stations = Hash.new { |h, k| h[k] = Stats.new }
      file = Pathname(__dir__).join("measurements.txt")

      File.open(file, "r:UTF-8") do |f|
        f.each_line do |line|
          # marginal speedup over splitting the string
          name = line.slice!(0, line.index(";"))
          stations[name].add_measurement(BigDecimal(line[1..]))
        end
      end

      "{#{
        stations.sort.map do |name, stats|
          "#{name}=#{stats}"
        end.join(', ')}}"
    end
  end
end
