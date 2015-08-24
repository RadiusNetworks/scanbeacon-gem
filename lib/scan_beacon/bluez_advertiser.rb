module ScanBeacon
  class BlueZAdvertiser
 
    attr_accessor :beacon, :parser, :ad

    def initialize(opts = {})
      @device_id = opts[:device_id] || BlueZ.devices[0][:device_id]
      BlueZ.device_up @device_id
      self.beacon = opts[:beacon]
      self.parser = opts[:parser]
      self.parser ||= BeaconParser.default_parsers.find {|parser| parser.beacon_type == beacon.beacon_types.first}
    end

    def beacon=(value)
      @beacon = value
      update_ad
    end

    def parser=(value)
      @parser = value
      update_ad
    end

    def ad=(value)
      @ad = value
      BlueZ.advertisement_bytes = @ad
    end

    def start
      BlueZ.start_advertising
    end

    def stop
      BlueZ.stop_advertising
    end

    def inspect
      "<BlueZAdvertiser ad=#{@ad.inspect}>"
    end

    def update_ad
      self.ad = @parser.generate_ad(@beacon) if @parser && @beacon
    end

  end
end
