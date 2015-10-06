module ScanBeacon
  class GenericAdvertiser
    attr_accessor :beacon, :parser, :ad

    def initialize(opts = {})
      self.beacon = opts[:beacon]
      self.parser = opts[:parser]
      if beacon
        self.parser ||= BeaconParser.default_parsers.find {|parser| parser.beacon_type == beacon.beacon_types.first}
      end
      @advertising = false
    end
    
    def start(with_rotation = false)
      raise NotImplementedError
    end

    def stop
      raise NotImplementedError
    end

    def inspect
      raise NotImplementedError
    end
  end
end