require 'set'

module ScanBeacon
  class Beacon

    attr_accessor :mac, :ids, :power, :beacon_types

    def initialize(opts={})
      @ids = opts[:ids]
      @power = opts[:power]
      @beacon_types = Set.new [opts[:beacon_type]]
      @rssis = []
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
      "#{ids[0][0..7]}-#{ids[0][8..11]}-#{ids[0][12..15]}-#{ids[0][16..19]}-#{ids[0][19..-1]}".upcase
    end

    def major
      ids[1]
    end

    def minor
      ids[2]
    end

    def inspect
      "<Beacon ids=#{@ids.join(",")} rssi=#{rssi}, scans=#{@rssis.size}, power=#{@power}, type=\"#{@beacon_types.to_a.join(",")}\">"
    end
  end
end
