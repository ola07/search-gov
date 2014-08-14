require 'spec_helper'

describe OdieImageSearch do
  fixtures :affiliates, :flickr_profiles

  let(:affiliate) { affiliates(:basic_affiliate) }
  let(:search_engine_response) do
    SearchEngineResponse.new do |search_response|
      search_response.total = 2
      search_response.start_record = 1
      search_response.results = [Hashie::Rash.new(title: 'President Obama walks the Obama daughters to school', url: "http://url1", thumbnail_url: "http://thumbnailurl1"), Hashie::Rash.new(title: 'POTUS gets in car.', url: "http://url2", thumbnail_url: "http://thumbnailurl2")]
      search_response.end_record = 2
    end
  end

  before do
    oasis_search = mock(OasisSearch)
    OasisSearch.stub(:new).and_return oasis_search
    oasis_search.stub(:execute_query).and_return search_engine_response
  end

  describe ".search" do
    it "should retrieve photos from Oasis API endpoint" do
      image_search = OdieImageSearch.new(:query => 'obama', :affiliate => affiliate)
      image_search.run
      image_search.results.first["title"].should == 'President Obama walks the Obama daughters to school'
      image_search.results.last["title"].should == 'POTUS gets in car.'
      image_search.total.should == 2
    end
  end

  describe ".cache_key" do
    it "should output a key based on the query, affiliate id, and page parameters" do
      OdieImageSearch.new(:query => 'element', :affiliate => affiliate, :page => 4).cache_key.should == "oasis_image:element:#{affiliate.id}:4:10"
    end
  end

end
