module ScanBeacon
  class BeaconParser
    DEFAULT_LAYOUTS = {
      altbeacon: "m:2-3=beac,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25",
      eddystone_uid: "s:0-1=feaa,m:2-2=00,p:3-3:-41,i:4-13,i:14-19;d:20-21",
      eddystone_url: "s:0-1=feaa,m:2-2=10,p:3-3:-41,i:4-21v",
      eddystone_tlm: "s:0-1=feaa,m:2-2=20,d:3-3,d:4-5,d:6-7,d:8-11,d:12-15",
      eddystone_eid: "s:0-1=feaa,m:2-2=30,p:3-3:-41,i:4-11",
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
      if layout.include?("s")
        @ad_type = AD_TYPE_SERVICE
      else
        @ad_type = AD_TYPE_MFG
      end
      @layout = layout
      parse_layout
    end

    def parse_layout
      @matchers = []
      @ids = []
      @data_fields = []
      @power = nil
      @layout.split(",").each do |field|
        field_type, range_start, range_end, expected = field.split(/:|=|-/)
        field_params = {
          start: range_start.to_i,
          end: range_end.to_i,
          length: range_end.to_i - range_start.to_i + 1,
        }
        if range_end.end_with? 'v'
          field_params[:var_length] = true
        end
        field_params[:expected] = [expected].pack("H*") unless expected.nil?
        case field_type
        when 'm'
          @matchers << field_params
        when 's'
          # swap byte order of service uuid
          expected = field_params[:expected]
          field_params[:expected] = expected[1] + expected[0]
          @matchers << field_params
        when 'i'
          @ids << field_params
        when 'd'
          @data_fields << field_params
        when 'p'
          @power = field_params
        end
      end
    end

    def matches?(data)
      @matchers.each do |matcher|
        return false unless data[matcher[:start]..matcher[:end]] == matcher[:expected]
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
        Beacon::Field.new(bytes: elem_str)
      }
    end

    def parse_mfg_or_service_id(data)
      data[0..1].unpack('S<')[0]
    end

    def parse_power(data)
      return nil if @power.nil?
      power_data = data[@power[:start]..@power[:end]]
      return nil if power_data.nil?
      power_data.unpack('c')[0]
    end

    def generate_ad(beacon)
      length = [@matchers, @ids, @power, @data_fields].flatten.map {|elem| elem[:start] }.max + 1
      ad = ("\x00" * length).force_encoding("ASCII-8BIT")
      @matchers.each do |matcher|
        ad[matcher[:start]..matcher[:end]] = matcher[:expected]
      end
      @ids.each_with_index do |id, index|
        if id[:var_length]
          id_bytes = Beacon::Field.new(hex: beacon.ids[index]).bytes
          ad[id[:start]..id[:start]+id_bytes.size] = id_bytes
        else
          id_bytes = Beacon::Field.field_with_length(beacon.ids[index], id[:length]).bytes
          ad[id[:start]..id[:end]] = id_bytes
        end
      end
      @data_fields.each_with_index do |field, index|
        unless beacon.data[index].nil?
          field_bytes = Beacon::Field.field_with_length(beacon.data[index], field[:length]).bytes
          ad[field[:start]..field[:end]] = field_bytes
        end
      end
      ad[@power[:start]..@power[:end]] = [beacon.power].pack('c')
      length = ad.size
      if @ad_type == AD_TYPE_SERVICE
        "\x03\x03".force_encoding("ASCII-8BIT") + [beacon.service_uuid].pack("S<") + [length+1].pack('C') + BT_EIR_SERVICE_DATA + ad
      elsif @ad_type == AD_TYPE_MFG
        ad[0..1] = [beacon.mfg_id].pack("S<")
        [length+1].pack('C') + [AD_TYPE_MFG].pack('C') +  ad
      end
    end

    def inspect
      "<BeaconParser type=\"#{@beacon_type}\", layout=\"#{@layout}\">"
    end
  end
end
