module ScanBeacon
  class Advertisement

    attr_accessor :mac, :uuid, :major, :minor, :rssi, :power, :ad_type

    def initialize(payload)
      @payload = payload
      @rssi = payload.unpack('c')[0]
      @mac = payload[2..7].unpack('H2 H2 H2 H2 H2 H2').join(":").upcase
      @data = payload[11..-1]
      if @data.size >= 30
        @uuid = @data[9..24].unpack('H8-H4-H4-H4-H12').join("-").upcase
        @major, @minor, @power = @data[25..29].unpack("S>2c")
        if @data[7..8].unpack('H4')[0] == 'beac'
          @ad_type = :altbeacon
        else
          @ad_type = :ibeacon
        end
      end
    end

    def to_s
      "<Advertisement mac: #{@mac}, beacon: #{@uuid} : #{@major} : #{@minor}, rssi: #{@rssi}, power: #{@power}, ad_type: #{@ad_type}>"
    end

  end
end
