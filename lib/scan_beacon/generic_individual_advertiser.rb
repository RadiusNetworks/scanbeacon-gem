module ScanBeacon
  class GenericIndividualAdvertiser < GenericAdvertiser
    def initialize(opts={})
      @advertising = false
      @parser = nil
      super(opts)
    end

    def beacon=(value)
      @beacon = value
      update_ad
    end

    def parser=(value)
      @parser = value
      update_ad
    end

    def update_ad    
      self.ad = @parser.generate_ad(@beacon) if @parser && @beacon
      self.start if @advertising
    end
    
    def ad=(value)
      @ad = value
    end
  end
end