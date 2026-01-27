# frozen_string_literal: true

require "csv"
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

      CSV.foreach(file, headers: false, col_sep: ";") do |row|
        stations[row[0]].add_measurement(BigDecimal(row[1]))
      end

      "{#{
        stations.sort.map do |name, stats|
          "#{name}=#{stats}"
        end.join(', ')}}"
    end
  end
end
