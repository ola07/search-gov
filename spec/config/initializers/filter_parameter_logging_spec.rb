# frozen_string_literal: true

describe 'ActiveSupport::ParameterFilter' do
  let(:config) { Usasearch::Application.config }
  let(:parameter_filter) { ActiveSupport::ParameterFilter.new(config.filter_parameters) }

  it 'contains a lambda for handling query redaction' do
    expect(config.filter_parameters.any?(Proc)).to be true
  end

  it 'filters sayt q parameter' do
    expect(parameter_filter.filter('q' => 'bar')).to eq('q' => '[FILTERED]')
  end

  it 'redacts queries that may contain social security numbers' do
    expect(parameter_filter.filter('query' => '111-11-1111 tax return')).to eq('query' => 'REDACTED_SSN tax return')
  end

  it 'redacts queries that may contain email addresses' do
    expect(parameter_filter.filter('query' => 'contact someone@gsa.gov')).to eq('query' => 'contact REDACTED_EMAIL')
  end

  it 'redacts queries that may contain phone numbers' do
    expect(parameter_filter.filter('query' => 'call me at 123-456-7890')).to eq('query' => 'call me at REDACTED_PHONE')
  end

  it 'does not redact non-sensitive queries' do
    expect(parameter_filter.filter('query' => 'safe query')).to eq('query' => 'safe query')
  end
end
