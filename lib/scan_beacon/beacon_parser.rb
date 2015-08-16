module ScanBeacon
  class BeaconParser
    DEFAULT_LAYOUTS = {
      altbeacon: "m:2-3=beac,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25",
      eddystone_uid: "s:0-1=aafe,m:2-2=00,p:3-3:-41,i:4-13,i:14-19;d:20-21"
    }
    AD_TYPE_MFG = 0xff
    AD_TYPE_SERVICE = 0x03
    BT_EIR_SERVICE_DATA = "\x16"
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
      _, power_start, power_end = @layout.find {|item| item[0] == "p"}.split(/:|-/)
      @power = {start: power_start.to_i, end: power_end.to_i}
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
      parse_elems(@data_fields, data)
    end

    def parse_elems(elems, data)
      elems.map {|elem|
        elem_str = data[elem[:start]..elem[:end]]
        elem_length = elem_str.size
        case elem_length
        when 1
          elem_str.unpack('C')[0]
        when 2 
          # two bytes, so treat it as a short (big endian)
          elem_str.unpack('S>')[0]
        when 6
          # 6 bytes, treat it is an eddystone instance id
          ("\x00\x00"+elem_str).unpack('Q>')[0]
        else
          # not two bytes, so treat it as a hex string
          elem_str.unpack('H*').join
        end
      }
    end

    def parse_mfg_or_service_id(data)
      data[0..1].unpack('H*')[0]
    end

    def parse_power(data)
      data[@power[:start]..@power[:end]].unpack('c')[0]
    end

    def generate_ad(beacon)
      length = [@matchers, @ids, @power, @data_fields].flatten.map {|elem| elem[:end] }.max + 1
      ad = "\x00" * length
      @matchers.each do |matcher|
        ad[matcher[:start]..matcher[:end]] = [matcher[:expected]].pack("H*")
      end
      @ids.each_with_index do |id, index|
        ad[id[:start]..id[:end]] = generate_field(id, beacon.ids[index])
      end
      @data_fields.each_with_index do |field, index|
        ad[field[:start]..field[:end]] = generate_field(field, beacon.data[index]) unless beacon.data[index].nil?
      end
      ad[@power[:start]..@power[:end]] = [beacon.power].pack('c')
      if @ad_type == AD_TYPE_SERVICE
        "\x03\x03" + [beacon.service_uuid].pack("H*") + [length+1].pack('C') + BT_EIR_SERVICE_DATA + ad
      elsif @ad_type == AD_TYPE_MFG
        ad[0..1] = [beacon.mfg_id].pack("H*")
        [length+1].pack('C') + [AD_TYPE_MFG].pack('C') +  ad
      end
    end

    def generate_field(field, value)
      field_length = field[:end] - field[:start] + 1
      case field_length
      when 1
        [value].pack("c")
      when 2
        [value].pack("S>")
      when 6
        [value].pack("Q>")[2..-1]
      else
        [value].pack("H*")[0..field_length-1]
      end
    end 

    def inspect
      "<BeaconParser type=\"#{@beacon_type}\", layout=\"#{@layout.join(",")}\">"
    end
  end
end
