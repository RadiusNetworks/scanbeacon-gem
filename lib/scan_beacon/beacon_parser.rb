module ScanBeacon
  class BeaconParser

    attr_accessor :beacon_type

    @@parsers = []
    def self.add(parser)
      @@parsers << parser
    end

    def self.all
      @@parsers
    end

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

    def parse_ids(data)
      @ids.map {|id|
        if id[:end] - id[:start] == 1
          data[id[:start]..id[:end]].unpack('S>')[0]
        else
          data[id[:start]..id[:end]].unpack('H*').join
        end
      }
    end

    def parse_power(data)
      data[@power[:start]..@power[:end]].unpack('c')[0]
    end
  end
end
