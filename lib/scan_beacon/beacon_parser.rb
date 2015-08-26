module ScanBeacon
  class BeaconParser
    DEFAULT_LAYOUTS = {
      altbeacon: "m:2-3=beac,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25",
      eddystone_uid: "s:0-1=aafe,m:2-2=00,p:3-3:-41,i:4-13,i:14-19;d:20-21"
    }
    AD_TYPE_MFG = 0xff
    AD_TYPE_SERVICE = 0x03
    BT_EIR_SERVICE_DATA = "\x16".force_encoding("ASCII-8BIT")
    attr_accessor :beacon_type

    def self.default_parsers
      DEFAULT_LAYOUTS.map {|name, layout| BeaconParser.new name, layout }
    end

    def initialize(beacon_type, layout)
      @beacon_type = beacon_type
      @layout = layout.split(",")
      if layout.include?("s")
        @ad_type = AD_TYPE_SERVICE
      else
        @ad_type = AD_TYPE_MFG
      end
      @matchers = @layout.find_all {|item| ["m", "s"].include? item[0]}.map {|matcher|
        _, range_start, range_end, expected = matcher.split(/:|=|-/)
        {start: range_start.to_i, end: range_end.to_i, expected: expected}
      }
      @ids = @layout.find_all {|item| item[0] == "i"}.map {|id|
        _, range_start, range_end = id.split(/:|-/)
        {start: range_start.to_i, end: range_end.to_i}
      }
      @data_fields = @layout.find_all {|item| item[0] == "d"}.map {|field|
        _, range_start, range_end = field.split(/:|-/)
        {start: range_start.to_i, end: range_end.to_i}
      }
      power_parser =  @layout.find {|item| item[0] == "p"}
      if power_parser.nil?
        @power = nil
      else
        _, power_start, power_end = power_parser.split(/:|-/)
        @power = {start: power_start.to_i, end: power_end.to_i}
      end
    end

    def matches?(data)
      @matchers.each do |matcher|
        return false unless data[matcher[:start]..matcher[:end]].unpack("H*").join == matcher[:expected]
      end
      return true
    end

    def parse(data, ad_type = AD_TYPE_MFG)
      return nil if ad_type != @ad_type || !matches?(data)
      if @ad_type == AD_TYPE_MFG
        Beacon.new(ids: parse_ids(data), power: parse_power(data), beacon_type: @beacon_type,
          data: parse_data_fields(data), mfg_id: parse_mfg_or_service_id(data))
      else
        Beacon.new(ids: parse_ids(data), power: parse_power(data), beacon_type: @beacon_type,
          data: parse_data_fields(data), service_uuid: parse_mfg_or_service_id(data))
      end
    end

    def parse_ids(data)
      parse_elems(@ids, data)
    end

    def parse_data_fields(data)
      parse_elems(@data_fields, data).map(&:bytes)
    end

    def parse_elems(elems, data)
      elems.map {|elem|
        elem_str = data[elem[:start]..elem[:end]]
        BeaconId.new(bytes: elem_str)
      }
    end

    def parse_mfg_or_service_id(data)
      data[0..1].unpack('S>')[0]
    end

    def parse_power(data)
      return nil if @power.nil?
      data[@power[:start]..@power[:end]].unpack('c')[0]
    end

    def generate_ad(beacon)
      length = [@matchers, @ids, @power, @data_fields].flatten.map {|elem| elem[:end] }.max + 1
      ad = ("\x00" * length).force_encoding("ASCII-8BIT")
      @matchers.each do |matcher|
        ad[matcher[:start]..matcher[:end]] = [matcher[:expected]].pack("H*")
      end
      @ids.each_with_index do |id, index|
        id_length = id[:end] - id[:start] + 1
        id_bytes = BeaconId.id_with_length(beacon.ids[index], id_length).bytes
        ad[id[:start]..id[:end]] = id_bytes
      end
      @data_fields.each_with_index do |field, index|
        unless beacon.data[index].nil?
          field_length = field[:end] - field[:start] + 1
          field_bytes = BeaconId.id_with_length(beacon.data[index], field_length).bytes
          ad[field[:start]..field[:end]] = field_bytes
        end
      end
      ad[@power[:start]..@power[:end]] = [beacon.power].pack('c')
      if @ad_type == AD_TYPE_SERVICE
        "\x03\x03".force_encoding("ASCII-8BIT") + [beacon.service_uuid].pack("S<") + [length+1].pack('C') + BT_EIR_SERVICE_DATA + ad
      elsif @ad_type == AD_TYPE_MFG
        ad[0..1] = [beacon.mfg_id].pack("S<")
        [length+1].pack('C') + [AD_TYPE_MFG].pack('C') +  ad
      end
    end

    def inspect
      "<BeaconParser type=\"#{@beacon_type}\", layout=\"#{@layout.join(",")}\">"
    end
  end
end
