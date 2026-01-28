# frozen_string_literal: true
RubyVM::YJIT.enable

require "etc"

module V2
  Stats = Struct.new(:min, :max, :sum, :count) do
    def merge!(other)
      self.min = other.min if other.min < self.min
      self.max = other.max if other.max > self.max
      self.sum += other.sum
      self.count += other.count
      self
    end

    def to_s
      "#{(min / 10.0)}/#{((sum / count.to_f) / 10).round(1)}/#{(max / 10.0)}"
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
          stations = Hash.new(capacity: 500) { |h, k| h[k] = Stats.new(min: 999, max: -999, sum: 0, count: 0) }

          File.open(file, "r:UTF-8") do |f|
            f.seek(start_offset, IO::SEEK_SET)

            pos = start_offset
            # drop partial line at the beginning
            pos += f.gets.bytesize unless start_offset.zero?

            f.each_line do |line|
              # Find semicolon using byte scanning
              semi_pos = 0
              while line.getbyte(semi_pos) != 59 # ';'
                semi_pos += 1
              end
              name = line.byteslice(0, semi_pos)
              value = to_number_fast(line, semi_pos + 1)

              stat = stations[name]
              stat.min = value if value < stat.min
              stat.max = value if value > stat.max
              stat.sum += value
              stat.count += 1

              pos += line.bytesize
              break if pos > end_offset
            end
          end

          stations.default_proc = nil
          writer.write Marshal.dump(stations)
          writer.close
          exit!
        end

        writer.close
        pids << pid
      end

      all_stations = {}
      pipes.each do |r|
        worker_stations = Marshal.load(r.read)
        r.close
        worker_stations.each do |name, stats|
          if all_stations.key?(name)
            all_stations[name].merge!(stats)
          else
            all_stations[name] = stats
          end
        end
      end

      "{#{
        all_stations.sort.map do |name, stats|
          "#{name}=#{stats}"
        end.join(', ')}}"
    end

    def self.to_number_fast(str, start_idx)
      idx = start_idx
      negative = str.getbyte(idx) == 45 # '-'
      idx += 1 if negative

      result = 0
      while (b = str.getbyte(idx)) != 46 # '.'
        result = result * 10 + (b - 48) # '0' = 48
        idx += 1
      end
      result = result * 10 + (str.getbyte(idx + 1) - 48)

      negative ? -result : result
    end
  end

end
