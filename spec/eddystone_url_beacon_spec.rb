require 'spec_helper'
require 'scan_beacon'

module ScanBeacon
  RSpec.describe EddystoneUrlBeacon do
    let(:url) { "http://www.radiusnetworks.com" }
    let(:compressed_url) { "007261646975736e6574776f726b7307" }

    it "can compress a url according to the Eddystone-URL spec" do
      expect(EddystoneUrlBeacon.compress_url(url)).to eq compressed_url
    end

    it "can decompress an url according to the Eddystone-URL spec" do
      expect(EddystoneUrlBeacon.decompress_url(compressed_url)).to eq url
    end

    it "can be initialized with a url parameter and produce the proper ids" do
      beacon = EddystoneUrlBeacon.new(url: url)
      expect(beacon.ids).to eq [compressed_url]
    end

    it "can be initialized with a hex id parameter and return the decompressed url" do
      beacon = EddystoneUrlBeacon.new(ids: [compressed_url])
      expect(beacon.url).to eq url
    end

    it "should raise InvalidArgument when given an invalid url to compress" do
      expect{ EddystoneUrlBeacon.compress_url "foobar" }.to raise_error ArgumentError
    end

    it "should raise InvalidArgument when given a url to compress that is too long" do
      expect{ EddystoneUrlBeacon.compress_url "http://google.com/url_is_too_long" }.to raise_error ArgumentError
    end

    it "should raise InvalidArgument when a url can't be decompressed" do
      expect{ EddystoneUrlBeacon.decompress_url "garbage" }.to raise_error ArgumentError
    end
  end
end
