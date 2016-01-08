module ScanBeacon
  # Convenience class for constructing & advertising Eddystone-URL frames
  class EddystoneUrlBeacon < Beacon

    attr_accessor :url

    SCHEMES = {"http://www."  => "\x00",
               "https://www." => "\x01",
               "http://"      => "\x02",
               "https://"     => "\x03"}

    EXPANSIONS = {".com/"  => "\x00",
                  ".org/"  => "\x01",
                  ".edu/"  => "\x02",
                  ".net/"  => "\x03",
                  ".info/" => "\x04",
                  ".biz/"  => "\x05",
                  ".gov/"  => "\x06",
                  ".com"   => "\x07",
                  ".org"   => "\x08",
                  ".edu"   => "\x09",
                  ".net"   => "\x0a",
                  ".info"  => "\x0b",
                  ".biz"   => "\x0c",
                  ".gov"   => "\x0d"}

    def initialize(opts = {})
      @url = opts[:url]
      opts[:ids] = [compressed_url_hex]
      opts[:service_uuid] ||= 0xFEAA
      opts[:beacon_type] ||= :eddystone_url
      super opts
    end

    def url=(new_url)
      @url = new_url
      self.ids = [compressed_url_hex]
    end

    def compressed_url
      scheme, scheme_code = SCHEMES.find {|k, v| url.start_with? k}
      compressed_url = scheme_code + self.url[scheme.size..-1]
      EXPANSIONS.each do |k,v|
        compressed_url.gsub! k,v
      end
      return compressed_url.force_encoding("ASCII-8BIT")
    end

    def compressed_url_hex
      self.compressed_url.unpack("H*")[0]
    end

    def inspect
      "<EddystoneUrlBeacon url=#{@ids.join(",")} rssi=#{rssi}, scans=#{ad_count}, power=#{@power}>"
    end
  end
end
