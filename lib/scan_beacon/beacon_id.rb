module ScanBeacon
  class BeaconId
    include Comparable
    ENCODING = "ASCII-8BIT".freeze
    NULL_BYTE = "\x00".force_encoding(ENCODING).freeze

    def initialize(bytes: nil, hex: nil, number: nil, length: nil)
      self.set_data(bytes: bytes, hex: hex, number: number, length: length)
    end

    def self.id_with_length(id, length)
      return id if id.is_a? BeaconId
      if id.is_a? String
        BeaconId.new hex: id, length: length
      elsif id.is_a? Fixnum
        BeaconId.new number: id, length: length
      end
    end

    def set_data(bytes: nil, hex: nil, number: nil, length: nil)
      if bytes
        @data = bytes.force_encoding(ENCODING)
      elsif hex
        # zero pad hex if needed
        hex = "0"*(length*2-hex.size) + hex if length and hex.size < length*2
        @data = [hex].pack("H*")
      elsif number
        raise ArgumentError.new("Must also give a field length when you give a number") if length.nil?
        set_data(hex: number.to_s(16), length: length)
      end
    end

    def value
      if @data.size < 6
        self.to_i
      else
        self.to_hex
      end
    end

    def to_s
      value.to_s
    end

    def inspect
      "<BeaconId value=#{self.value.inspect}>"
    end

    def bytes
      @data
    end

    def to_i
      size = @data.size
      case size
      when 0
        nil
      when 1
        @data.unpack("C")[0]
      when 2
        @data.unpack("S>")[0]
      when 3
        (NULL_BYTE + @data).unpack("L>")[0]
      when 4
        @data.unpack("L>")[0]
      when 5,6,7
        (NULL_BYTE*(8-size) + @data).unpack("Q>")[0]
      when 8
        @data.unpack("Q>")[0]
      else
        @data[-8..-1].unpack("Q>")[0]
      end
    end

    def to_hex
      @data.unpack("H*")[0]
    end

    def <=> (other)
      if other.is_a? BeaconId
        self.bytes <=> other.bytes
      else
        self.value <=> other
      end
    end
  end
end
