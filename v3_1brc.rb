# frozen_string_literal: true
RubyVM::YJIT.enable

module V3
  def self.compute

    station_temperate_stats = Hash.new do |h, k|
      h[k] = [999, -999, 0, 0]
    end

    file = Pathname(__dir__).join("measurements.txt")

    File.open(file, "r:UTF-8") do |f|
      f.each_line do |line|
        seperator_pos = line.byteindex(";")
        station_name = line.byteslice(0, seperator_pos)
        temperature_reading = parse(line, seperator_pos + 1)

        current_stats = station_temperate_stats[station_name]
        current_stats[0] = temperature_reading if temperature_reading < current_stats[0]
        current_stats[1] = temperature_reading if temperature_reading > current_stats[1]
        current_stats[2] += temperature_reading
        current_stats[3] += 1
      end
    end

    "{#{
      station_temperate_stats.sort.map do |station_name, stats|
        formatted_stats = "#{(stats[0] / 10.0)}/#{((stats[2] / stats[3].to_f) / 10).round(1)}/#{(stats[1] / 10.0)}"
        "#{station_name}=#{formatted_stats}"
      end.join(', ')}}"
  end

  def self.parse(raw_temperate_reading, start_idx)
    idx = start_idx
    negative = raw_temperate_reading.getbyte(idx) == 45 # '-'
    idx += 1 if negative

    result = 0
    while (b = raw_temperate_reading.getbyte(idx)) != 46 # '.'
      result = result * 10 + (b - 48) # '0' = 48
      idx += 1
    end
    result = result * 10 + (raw_temperate_reading.getbyte(idx + 1) - 48)

    negative ? -result : result
  end
end
