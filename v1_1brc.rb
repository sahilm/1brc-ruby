# frozen_string_literal: true
RubyVM::YJIT.enable


module V1
  Stats = Struct.new(:min, :max, :sum, :count) do
    def initialize
      super(999, -999, 0, 0)
    end

    def add_measurement(value)
      self.min = value if value < min
      self.max = value if value > max
      self.sum += value
      self.count += 1
    end

    def to_s
      "#{(min / 10.0)}/#{((sum / count.to_f) / 10).round(1)}/#{(max / 10.0)}"
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
          value = to_number(line[1..])
          stations[name].add_measurement(value)
        end
      end

      "{#{
        stations.sort.map do |name, stats|
          "#{name}=#{stats}"
        end.join(', ')}}"
    end

    def self.to_number(number_string)
      is_negative = number_string.start_with?("-")
      if is_negative
        number_string.slice!(0)
      end
      number = (number_string.slice!(0..number_string.index(".")).to_i * 10) + number_string.to_i

      is_negative ? -number : number
    end
  end
end
