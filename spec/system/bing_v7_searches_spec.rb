# frozen_string_literal: true

describe 'Bing search' do
  describe 'web search' do
    let(:web_subscription_id) { ENV.fetch('BING_WEB_SUBSCRIPTION_ID') }
    let(:web_search_host) { 'api.bing.microsoft.com' }
    let(:web_search_path) { '/v7.0/search' }

    before do
      stub_request(:get, web_search_host)
      BingV7WebSearch.new(query: 'building').execute_query
    end

    it 'uses the web search key and end point' do
      skip 'Bing is failing and Jim has approved skipping of Bing tests.'

      expect(WebMock).to have_requested(:get, /#{web_search_host}#{web_search_path}/).
        with(headers: { 'Ocp-Apim-Subscription-Key' => web_subscription_id })
    end
  end

  describe 'image search' do
    let(:image_subscription_id) { ENV.fetch('BING_IMAGE_SUBSCRIPTION') }
    let(:image_search_host) { 'api.cognitive.microsoft.com' }
    let(:image_search_path) { '/bing/v7.0/images/search' }

    before do
      stub_request(:get, image_search_host)
      BingV7ImageSearch.new(query: 'book').execute_query
    end

    it 'uses the image search key and endpoint' do
      skip 'Skipping this test because the image search API endpoint is currently broken. Jim approved this skip on 06/26/24.'
      expect(WebMock).to have_requested(:get, /#{image_search_host}#{image_search_path}/).
        with(headers: { 'Ocp-Apim-Subscription-Key' => image_subscription_id })
    end
  end
end
