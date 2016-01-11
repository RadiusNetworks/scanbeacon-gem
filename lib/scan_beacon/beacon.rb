require 'set'

module ScanBeacon
  class Beacon

    attr_accessor :mac, :ids, :power, :beacon_types, :data, :mfg_id, :service_uuid, :rssis

    def initialize(opts={})
      @ids = opts[:ids] || []
      @data = opts[:data] || []
      @power = opts[:power]
      @mfg_id = opts[:mfg_id]
      @service_uuid = opts[:service_uuid]
      @beacon_types = Set.new [opts[:beacon_type]]
      @rssis = opts[:rssis] || []
    end

    def ==(obj)
      obj.is_a?(Beacon) && obj.mac == @mac && obj.ids == @ids
    end

    def add_rssi(val)
      @rssis << val
    end

    def add_type(val)
      @beacon_types << val
    end

    def rssi
      @rssis.inject(0) {|sum, el| sum += el} / @rssis.size.to_f
    end

    def uuid
      id0 = ids[0].to_s
      "#{id0[0..7]}-#{id0[8..11]}-#{id0[12..15]}-#{id0[16..19]}-#{id0[20..-1]}".upcase
    end

    def major
      ids[1].to_i
    end

    def minor
      ids[2].to_i
    end

    def ad_count
      @rssis.size
    end

    def inspect
      "<Beacon ids=#{@ids.join(",")} rssi=#{rssi}, scans=#{ad_count}, power=#{@power}, type=\"#{@beacon_types.to_a.join(",")}\">"
    end
  end
end
