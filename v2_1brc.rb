# frozen_string_literal: true
RubyVM::YJIT.enable

require "etc"
require "bigdecimal"

module V2
  Stats = Struct.new(:min, :max, :sum, :count) do
    def add_measurement(value)
      self.min = value if value < min
      self.max = value if value > max
      self.sum += value
      self.count += 1
    end

    def merge(other)
      Stats.new(min: [self.min, other.min].min,
                max: [self.max, other.max].max,
                sum: self.sum + other.sum,
                count: self.count + other.count)
    end

    def to_s
      avg_rounded = (2 * sum + count) / (2 * count)
      "#{min / 10.0}/#{avg_rounded / 10.0}/#{max / 10.0}"
    end
  end

  class OneBRC
    def self.compute
      file = Pathname(__dir__).join("measurements.txt")
      num_workers = Etc.nprocessors
      chunk_size = file.size / num_workers
      pipes = []
      pids = []

      (0..num_workers - 1).map do |i|
        start_offset = i * chunk_size
        end_offset = start_offset + chunk_size
        [start_offset, end_offset]
      end.each do |start_offset, end_offset|
        reader, writer = IO.pipe
        reader.binmode
        writer.binmode
        pipes << reader

        pid = fork do
          reader.close
          stations = Hash.new

          File.open(file, "r:UTF-8") do |f|
            f.seek(start_offset, IO::SEEK_SET)

            pos = start_offset
            # drop partial line at the beginning
            pos += f.gets.bytesize unless start_offset.zero?

            f.each_line do |line|
              name = line.slice!(0, line.index(";"))
              value = to_number(line[1..])

              stations[name] ||= Stats.new(min: 999, max: -999, sum: 0, count: 0)
              stations[name].add_measurement(value)

              pos += line.bytesize
              break if pos > end_offset
            end
          end

          writer.write Marshal.dump(stations)
          writer.close
          exit!
        end

        writer.close
        pids << pid
      end

      all_stations = pipes.map do |r|
        Marshal.load(r.read)
      ensure
        r.close
      end.reduce({}) do |acc, station|
        acc.merge(station) do |_, s1, s2|
          s1.merge(s2)
        end
      end

      "{#{
        all_stations.sort.map do |name, stats|
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
