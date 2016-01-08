require 'spec_helper'
require 'scan_beacon'

module ScanBeacon
  RSpec.describe EddystoneUrlBeacon do
    let(:url) { "http://www.radiusnetworks.com" }
    let(:beacon) { EddystoneUrlBeacon.new(url: url) }

    it "can compress a url according to the Eddystone-URL spec" do
      expect(beacon.compressed_url).to eq "\x00radiusnetworks\a"
    end

    it "can be used to create a beacon object with the proper id field" do
      expect(beacon.ids).to eq ["007261646975736e6574776f726b7307"]
    end
  end
end
