module ScanBeacon
  # Convenience class for constructing & advertising Eddystone-URL frames
  class EddystoneUrlBeacon < Beacon

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
      opts[:service_uuid] ||= 0xFEAA
      opts[:beacon_type] ||= :eddystone_url
      super opts
      self.url = opts[:url] if opts[:url]
    end

    def self.from_beacon(beacon)
      new(ids: beacon.ids, power: beacon.power, rssis: beacon.rssis)
    end

    def url
      @url ||= self.class.decompress_url( self.ids[0].to_s )
    end

    def url=(new_url)
      @url = new_url
      self.ids = [self.class.compress_url(@url)]
    end

    def self.compress_url(url)
      scheme, scheme_code = SCHEMES.find {|k, v| url.start_with? k}
      raise ArgumentError, "Invalid URL" if scheme.nil?
      compressed_url = scheme_code + url[scheme.size..-1]
      EXPANSIONS.each do |k,v|
        compressed_url.gsub! k,v
      end
      raise ArgumentError, "URL too long" if compressed_url.size > 18
      compressed_url.force_encoding("ASCII-8BIT").unpack("H*")[0]
    end

    def self.decompress_url(hex)
      compressed_url_string = [hex].pack("H*")
      scheme_code = compressed_url_string[0]
      scheme, scheme_code = SCHEMES.find {|k,v| v == scheme_code}
      raise ArgumentError, "Invalid URL" if scheme.nil?
      decompressed_url = scheme + compressed_url_string[1..-1]
      EXPANSIONS.each do |k,v|
        decompressed_url.gsub! v,k
      end
      decompressed_url
    end

    def inspect
      "<EddystoneUrlBeacon url=\"#{url}\" rssi=#{rssi}, scans=#{ad_count}, power=#{@power}>"
    end
  end
end
