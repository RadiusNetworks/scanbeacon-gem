module ScanBeacon
  class InterleavedAdvertiser
    attr_accessor :beacons, :parsers, :advertiser
    # We will cycle through each beacon sequentially over the course of the time below
    INTERLEAVE_CYCLE_MILLIS = 1000
    
    def initialize(opts = {})
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
    end

    def stop
      if @thread
        @stop_requested = true
        @thread.join
        @thread = nil      
      end
    end

  private
    def start_interleaving_thread
      sleep_time = 1000.0/INTERLEAVE_CYCLE_MILLIS/beacons.size
      @stop_requested = false
      @thread = Thread.new do
        while !@stop_requested do
          beacons.each_with_index do |beacon, index|
            advertiser.stop
            break if @stop_requested
            advertiser.beacon = beacon
            puts "**** starting advertising with parser #{parsers[index]} and beacon #{beacon}"
            advertiser.parser = parsers[index]
            advertiser.start
            sleep sleep_time        
          end
        end
      end
    end    
    
  end
end