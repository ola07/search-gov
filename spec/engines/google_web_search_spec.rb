# coding: utf-8
require 'spec_helper'

describe GoogleWebSearch do

  it_behaves_like "a web search engine"

  describe ".new for GoogleWebSearch" do
    it 'should assign start' do
      GoogleWebSearch.new(query: 'gov', offset: 15).start.should == 16
    end

    context 'when only required search params are passed in' do
      let(:minimum_search) { GoogleWebSearch.new(query: "taxes") }
      it 'should set appropriate defaults' do
        minimum_search.query.should == 'taxes'
        minimum_search.filter_level.should == 'medium'
      end
    end

    context 'when all search params are passed in' do
      let(:fully_specified_search) { GoogleWebSearch.new(query: "taxes", offset: 11, filter: 2) }
      it 'should set appropriate values from params' do
        fully_specified_search.query.should == 'taxes'
        fully_specified_search.offset.should == 11
        fully_specified_search.filter_level.should == 'high'
      end
    end

    describe "adult content filters" do
      context "when a valid filter parameter is present" do
        it "should set the filter_level parameter to the Google-specific level" do
          GoogleWebSearch.new(query: "taxes", filter: 0).filter_level.should == 'off'
          GoogleWebSearch.new(query: "taxes", filter: 1).filter_level.should == 'medium'
          GoogleWebSearch.new(query: "taxes", filter: 2).filter_level.should == 'high'
        end
      end

      context "when the filter parameter is blank/invalid" do
        it "should set the filter_level parameter to the default value (medium)" do
          GoogleWebSearch.new(query: "taxes", filter: '').filter_level.should == 'medium'
          GoogleWebSearch.new(query: "taxes", filter: 'whatevs').filter_level.should == 'medium'
        end
      end
    end
  end

  context 'when affiliate-specific google CX is set' do
    let(:web_search) { GoogleWebSearch.new(query: "customcx", google_cx: '1234567890.abc') }

    it "should use that for the Google API call" do
      response = web_search.execute_query
      first = response.results.first
      first.title.should == "Using custom google CX"
    end
  end

end