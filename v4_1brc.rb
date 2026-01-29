# frozen_string_literal: true

RubyVM::YJIT.enable

require "etc"

module V4
  def self.compute
    file = Pathname(__dir__).join("measurements.txt")
    num_workers = Etc.nprocessors
    chunk_size = file.size / num_workers
    pipes = []
    pids = []
    semicolon_byte_value = ";".bytes.first

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
        station_stats = Hash.new { |h, k| h[k] = [999, -999, 0, 0] }

        File.open(file, "r:UTF-8") do |f|
          f.seek(start_offset, IO::SEEK_SET)

          pos = start_offset
          pos += f.gets.bytesize unless start_offset.zero?

          f.each_line do |line|
            separator_pos = find_separator_position(line, semicolon_byte_value)
            station_name = line.byteslice(0, separator_pos)
            temperature = parse(line, separator_pos + 1)

            stats = station_stats[station_name]
            stats[0] = temperature if temperature < stats[0]
            stats[1] = temperature if temperature > stats[1]
            stats[2] += temperature
            stats[3] += 1

            pos += line.bytesize
            break if pos > end_offset
          end
        end

        station_stats.default_proc = nil
        writer.write Marshal.dump(station_stats)
        writer.close
        exit!
      end

      writer.close
      pids << pid
    end

    all_stations = Hash.new { |h, k| h[k] = [999, -999, 0, 0] }
    pipes.each do |r|
      worker_stations = Marshal.load(r.read)
      r.close
      worker_stations.each do |name, stats|
        current = all_stations[name]
        current[0] = stats[0] if stats[0] < current[0]
        current[1] = stats[1] if stats[1] > current[1]
        current[2] += stats[2]
        current[3] += stats[3]
      end
    end

    pids.each { |pid| Process.wait(pid) }

    "{#{
      all_stations.sort.map do |station_name, stats|
        formatted_stats = "#{(stats[0] / 10.0)}/#{((stats[2] / stats[3].to_f) / 10).round(1)}/#{(stats[1] / 10.0)}"
        "#{station_name}=#{formatted_stats}"
      end.join(', ')}}"
  end

  def self.parse(raw_temperature_reading, start_idx)
    idx = start_idx
    negative = raw_temperature_reading.getbyte(idx) == 45 # '-'
    idx += 1 if negative

    result = 0
    while (b = raw_temperature_reading.getbyte(idx)) != 46 # '.'
      result = result * 10 + (b - 48) # '0' = 48
      idx += 1
    end
    result = result * 10 + (raw_temperature_reading.getbyte(idx + 1) - 48)

    negative ? -result : result
  end

  def self.find_separator_position(line, separator_byte)
    pos = 0
    while line.getbyte(pos) != separator_byte
      pos += 1
    end
    pos
  end
end
