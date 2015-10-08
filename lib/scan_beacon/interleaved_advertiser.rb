module ScanBeacon
  class InterleavedAdvertiser < GenericAdvertiser
    attr_accessor :beacons, :parsers, :advertiser
    # We will cycle through each beacon sequentially over the course of the time below
    INTERLEAVE_CYCLE_MILLIS = 1000
    
    def initialize(opts = {})
      super(opts)
      self.advertiser = opts[:advertiser]
      raise "No available advertiser" if advertiser.nil?
      self.beacons = opts[:beacons]
      if opts[:parsers]
        self.parsers = opts[:parsers]
      else
        self.parsers = []
        beacons.each do |beacon|
          self.parsers << BeaconParser.default_parsers.find {|parser| parser.beacon_type == beacon.beacon_types.first}
        end
      end
      raise "You must supply the same number of beacons (#{beacons.count}) and parsers (#{parsers.count})" if beacons.count != parsers.count
    end

    def start
      if beacons.size > 0
        start_interleaving_thread
      end
      @advertising = true
    end

    def stop
      if @thread
        @stop_requested = true
        @thread.join
        @thread = nil      
        advertiser.stop
      end
      @advertising = false
    end

    def inspect
      "<InterleavedAdvertiser beacons=#{@beacons.inspect}>"
    end

  private
    def start_interleaving_thread
      sleep_time = 1000.0/INTERLEAVE_CYCLE_MILLIS/beacons.size
      @stop_requested = false
      @thread = Thread.new do
        # Get all advertisements up front
        ads = []
        beacons.each_with_index do |beacon, index|
          parser = parsers[index]
          ads << parser.generate_ad(beacon)
        end
        
        while !@stop_requested do
          ads.each do |ad|
            advertiser.ad=ad
            advertiser.start if !advertiser.advertising
            sleep sleep_time        
            break if @stop_requested
          end
        end
      end
    end    
    
  end
end