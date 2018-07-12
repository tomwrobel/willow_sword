require 'spec_helper'
require 'willow_sword/dc_crosswalk'

RSpec.describe WillowSword::DcCrosswalk do
  describe 'DcCrosswalk with no source' do
    before(:each) do
      @src = nil
      @src = File.join(ENGINE_RAILS_ROOT, 'spec', 'fixtures', 'dc.xml')
      @no_src = File.join(ENGINE_RAILS_ROOT, 'spec', 'fixtures', 'dc2.xml')
      @dc = WillowSword::DcCrosswalk.new(@src)
    end

    it "should have the dublin core terms" do
      expect(@dc.terms).to be_kind_of(Array)
      expect(@dc.terms.size).to eq(55)
    end

    it "should have the translated terms" do
      expect(@dc.translated_terms).to be_kind_of(Hash)
      expect(@dc.translated_terms).to include('created')
    end

    it "should have the singular terms" do
      expect(@dc.singular).to be_kind_of(Array)
      expect(@dc.singular).to include('rights')
    end

    it 'should have no metadata' do
      expect(@dc.translated_terms).to be_kind_of(Hash)
      expect(@dc.metadata).to be_empty
    end

    it 'should return without erroring' do
      @dc.map_xml
      expect(@dc.translated_terms).to be_kind_of(Hash)
      expect(@dc.metadata).to be_empty
    end

  end
end
