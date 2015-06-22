module ScanBeacon
  class BeaconParser

    attr_accessor :beacon_type

    def initialize(beacon_type, layout)
      @beacon_type = beacon_type
      @layout = layout.split(",")
      @matchers = @layout.find_all {|item| item[0] == "m"}.map {|matcher|
        _, range_start, range_end, expected = matcher.split(/:|=|-/)
        {start: range_start.to_i, end: range_end.to_i, expected: expected}
      }
      @ids = @layout.find_all {|item| item[0] == "i"}.map {|id|
        _, range_start, range_end = id.split(/:|-/)
        {start: range_start.to_i, end: range_end.to_i}
      }
      _, power_start, power_end = @layout.find {|item| item[0] == "p"}.split(/:|-/)
      @power = {start: power_start.to_i, end: power_end.to_i}
    end

    def matches?(data)
      @matchers.each do |matcher|
        return false unless data[matcher[:start]..matcher[:end]].unpack("H*").join == matcher[:expected]
      end
      return true
    end

    def parse(data)
      return nil if !matches?(data)
      Beacon.new(ids: parse_ids(data), power: parse_power(data), beacon_type: @beacon_type)
    end

    def parse_ids(data)
      @ids.map {|id|
        if id[:end] - id[:start] == 1
          # two bytes, so treat it as a short (big endian)
          data[id[:start]..id[:end]].unpack('S>')[0]
        else
          # not two bytes, so treat it as a hex string
          data[id[:start]..id[:end]].unpack('H*').join
        end
      }
    end

    def parse_power(data)
      data[@power[:start]..@power[:end]].unpack('c')[0]
    end

    def inspect
      "<BeaconParser type=\"#{@beacon_type}\", layout=\"#{@layout.join(",")}\">"
    end
  end
end
