# frozen_string_literal: true

describe BingV7ImageSearch do
  subject(:search) { described_class.new(options) }

  it_behaves_like 'a Bing search'
  it_behaves_like 'an image search'

  it 'uses the correct host' do
    expect(described_class.api_host).to eq('https://api.cognitive.microsoft.com')
  end

  it 'uses the correct endpoint' do
    expect(described_class.api_endpoint).to eq('/bing/v7.0/images/search')
  end

  describe '#hosted_subscription_key' do
    let(:options) { {} }

    before do
      ENV['BING_IMAGE_SUBSCRIPTION'] = 'image key'
    end

    it 'uses the image search key' do
      expect(search.hosted_subscription_key).to eq('image key')
    end
  end
end
