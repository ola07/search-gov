require 'spec_helper'

describe NewsSearch do
  fixtures :affiliates, :rss_feed_urls, :rss_feeds, :navigations, :news_items, :youtube_profiles

  let(:affiliate) { affiliates(:basic_affiliate) }

  before(:all) do
    NewsItem.all.each { |news_item| news_item.save! }
    ElasticNewsItem.commit
  end

  describe "#initialize(options)" do
    let(:feed) { affiliate.rss_feeds.first }

    context 'when the parameter is hour' do
      it 'should find just the last hour' do
        search = NewsSearch.new(:query => '   element   OR', :tbs => "h", :affiliate => affiliate)
        (search.since.to_i - 1.hour.ago.to_i).should <= 5
      end
    end

    context 'when the parameter is not hour' do
      it "should set the time-based search parameter based on the beginning of the day" do
        search = NewsSearch.new(:query => '   element   OR', :tbs => "w", :affiliate => affiliate)
        search.since.to_i.should == Time.current.advance(weeks: -1).beginning_of_day.to_i
      end
    end

    context "when the tbs param isn't set" do
      it "should set 'since' to nil" do
        NewsSearch.new(:query => 'element', :affiliate => affiliate).since.should be_nil
      end
    end

    context "when the tbs param isn't valid" do
      it "should set 'since' to nil" do
        NewsSearch.new(:query => 'element', :tbs => "invalid", :affiliate => affiliate).since.should be_nil
      end
    end

    context "when a valid RSS feed is specified" do
      it "should set the rss_feed member" do
        NewsSearch.new(:query => 'element', :channel => feed.id, :affiliate => affiliate).rss_feed.should == feed
      end
    end

    context "when another affiliate's RSS feed is specified" do
      it "should set the rss_feed member to nil" do
        another_feed = rss_feeds(:another)
        NewsSearch.new(:query => 'element', :channel => another_feed.id, :affiliate => affiliate).rss_feed.should be_nil
      end
    end

    context 'when channel is not a valid number' do
      it 'should set the rss_feed member to nil' do
        NewsSearch.new(query: 'element', channel: { 'foo' => 'bar' }, affiliate: affiliate).rss_feed.should be_nil
      end
    end

    context "when the query param isn't set" do
      it "should set 'query' to a blank string" do
        NewsSearch.new(:channel => feed.id, :affiliate => affiliate).query.should be_blank
      end
    end

    context 'when the since_date param is valid' do
      it 'should set since to a parsed Date' do
        news_search = NewsSearch.new(channel: feed.id, affiliate: affiliate, since_date: '10/1/2012')
        news_search.since.to_s.should == '2012-10-01 00:00:00 UTC'
        news_search.until.should be_nil
      end
    end

    context 'when until_date is not present and the since_date param is not valid' do
      it 'should set since to a year ago' do
        news_search = NewsSearch.new(channel: feed.id, affiliate: affiliate, since_date: '13/41/2012')
        news_search.since.should == Time.current.advance(years: -1).beginning_of_day
        news_search.until.should be_nil
      end
    end

    context 'when until_date is present and the since_date param is not valid' do
      it 'should set since to a year ago before until_date' do
        news_search = NewsSearch.new(channel: feed.id, affiliate: affiliate, since_date: '13/41/2012', until_date: '10/15/2012')
        news_search.since.to_s == '2011-10-15 00:00:00 UTC'
        news_search.until.to_s == '2012-10-15 23:59:59 UTC'
      end
    end

    context 'when the until_date param is valid' do
      it 'should set until to the end of day of that date' do
        news_search = NewsSearch.new(channel: feed.id, affiliate: affiliate, until_date: '10/31/2012')
        news_search.since.should be_nil
        news_search.until.to_s.should == '2012-10-31 23:59:59 UTC'
      end
    end

    context 'when the until_date param is not valid' do
      it 'should set until to the end of day' do
        news_search = NewsSearch.new(channel: feed.id, affiliate: affiliate, until_date: '13/41/2012')
        news_search.since.should be_nil
        news_search.until.should == Time.current.end_of_day
      end
    end

    context 'when since_date is greater than until_date' do
      it 'should swap since and until' do
        news_search = NewsSearch.new(channel: feed.id, affiliate: affiliate, since_date: '10/31/2012', until_date: '9/1/2012')
        news_search.since.to_s.should == '2012-09-01 00:00:00 UTC'
        news_search.until.to_s.should == '2012-10-31 23:59:59 UTC'
      end
    end

    it 'should not overwrite per_page option' do
      news_search = NewsSearch.new(channel: feed.id, affiliate: affiliate, per_page: '15')
      news_search.per_page.should == 15
    end

    context 'when locale is set to :es' do
      before(:all) { I18n.locale = :es }

      context 'when the since_date param is valid' do
        it 'should use Spanish date format' do
          news_search = NewsSearch.new(channel: feed.id, affiliate: affiliate, since_date: '1/10/2012')
          news_search.since.to_s.should == '2012-10-01 00:00:00 UTC'
        end
      end

      context 'when the end_date param is valid' do
        it 'should use Spanish date format' do
          news_search = NewsSearch.new(channel: feed.id, affiliate: affiliate, until_date: '1/10/2012')
          news_search.until.to_s.should == '2012-10-01 23:59:59 UTC'
        end
      end

      after(:all) { I18n.locale = I18n.default_locale }
    end
  end

  describe "#run" do

    context "when searching with really long queries" do
      before do
        @search = NewsSearch.new(:query => "X" * (Search::MAX_QUERYTERM_LENGTH + 1), :affiliate => affiliate)
      end

      it "should return false when searching" do
        @search.run.should be_false
      end

      it "should have 0 results" do
        @search.run
        @search.results.size.should == 0
        @search.total.should == 0
        @search.module_tag.should be_nil
      end

      it "should set error message" do
        @search.run
        @search.error_message.should_not be_nil
      end
    end

    context "when searching with a blank query" do
      before do
        @search = NewsSearch.new(:query => "   ", :affiliate => affiliate)
      end

      it "should return true when searching" do
        @search.run.should be_true
      end

      it "should have more than 0 results" do
        @search.run
        @search.results.size.should > 0
      end

      it "should not set error message" do
        @search.run
        @search.error_message.should be_nil
      end
    end

    context "when a valid active RSS feed is specified" do
      it "should only search for news items from that feed" do
        feed = affiliate.rss_feeds.first
        search = NewsSearch.new(query: 'element', channel: feed.id, affiliate: affiliate,
                                contributor: 'contributor', publisher: 'publisher', subject: 'subject')
        ElasticNewsItem.should_receive(:search_for).
          with(q: 'element', rss_feeds: [feed], excluded_urls: affiliate.excluded_urls,
               since: nil, until: nil,
               offset: 0, size: 10,
               contributor: 'contributor', subject: 'subject', publisher: 'publisher',
               sort_by_relevance: false,
               tags: [], language: 'en')
        search.run.should be_true
      end
    end

    context "when a valid managed RSS feed is specified" do
      let(:feed) { rss_feeds(:managed_video) }
      let(:youtube_profile_feed) { rss_feeds(:nps_youtube_feed) }

      context 'when per_page option is not set' do
        it "should set per_page to 20" do
          search = NewsSearch.new(:query => 'element', :channel => feed.id, :affiliate => affiliate)
          ElasticNewsItem.should_receive(:search_for).
            with(q: 'element', rss_feeds: [youtube_profile_feed], excluded_urls: affiliate.excluded_urls,
                 since: nil, until: nil,
                 offset: 0, size: 20,
                 contributor: nil, subject: nil, publisher: nil,
                 sort_by_relevance: false,
                 tags: [], language: 'en')
          search.run.should be_true
        end
      end

      context 'when per_page option is set' do
        it 'should not change the initial per_page value' do
          search = NewsSearch.new(query: 'element', channel: feed.id, affiliate: affiliate, per_page: '15')
          ElasticNewsItem.should_receive(:search_for).
            with(q: 'element', rss_feeds: [youtube_profile_feed], excluded_urls: affiliate.excluded_urls,
                 since: nil, until: nil,
                 offset: 0, size: 15,
                 contributor: nil, subject: nil, publisher: nil,
                 sort_by_relevance: false,
                 tags: [], language: 'en')
          search.run.should be_true
        end
      end
    end

    context 'when a valid media RSS feed is specified' do
      let(:feed) { rss_feeds(:media_feed) }

      context 'when per_page option is not set' do
        it 'should set per_page to 20' do
          search = NewsSearch.new(:query => 'element', :channel => feed.id, :affiliate => affiliate)
          ElasticNewsItem.should_receive(:search_for).
            with(q: 'element', rss_feeds: [feed], excluded_urls: affiliate.excluded_urls,
                 since: nil, until: nil,
                 offset: 0, size: 20,
                 contributor: nil, subject: nil, publisher: nil,
                 sort_by_relevance: false,
                 tags: %w(image), language: 'en')
          search.run.should be_true
        end
      end

      context 'when per_page option is set' do
        it 'should not change the initial per_page value' do
          search = NewsSearch.new(query: 'element', channel: feed.id, affiliate: affiliate, per_page: '15')
          ElasticNewsItem.should_receive(:search_for).
            with(q: 'element', rss_feeds: [feed], excluded_urls: affiliate.excluded_urls,
                 since: nil, until: nil,
                 offset: 0, size: 15,
                 contributor: nil, subject: nil, publisher: nil,
                 sort_by_relevance: false,
                 tags: %w(image), language: 'en')
          search.run.should be_true
        end
      end
    end

    context "when no RSS feed is specified" do
      it "should search for news items from all active feeds for the affiliate" do
        one_week_ago = Time.current.advance(weeks: -1).beginning_of_day
        search = NewsSearch.new(query: 'element', tbs: 'w', affiliate: affiliate)
        ElasticNewsItem.should_receive(:search_for).
          with(q: 'element', rss_feeds: affiliate.rss_feeds.navigable_only, excluded_urls: affiliate.excluded_urls,
               since: one_week_ago, until: nil,
               offset: 0, size: 10,
               contributor: nil, subject: nil, publisher: nil,
               sort_by_relevance: false,
               tags: [], language: 'en')
        search.run
      end
    end

    context 'when searching with since_date' do
      it 'should search for NewsItem with since option' do
        feed = mock_model(RssFeed, is_managed?: false, show_only_media_content?: false)
        affiliate.stub_chain(:rss_feeds, :find_by_id).with(feed.id).and_return(feed)

        news_search = NewsSearch.new(query: 'element', channel: feed.id, affiliate: affiliate, since_date: '10/1/2012')
        ElasticNewsItem.should_receive(:search_for).
          with(q: 'element', rss_feeds: [feed], excluded_urls: affiliate.excluded_urls,
               since: Time.parse('2012-10-01 00:00:00Z'), until: nil,
               offset: 0, size: 10,
               contributor: nil, subject: nil, publisher: nil,
               sort_by_relevance: false,
               tags: [], language: 'en')

        news_search.run
      end
    end

    context 'when searching with until_date' do
      it 'should search for NewsItem with until option' do
        feed = mock_model(RssFeed, is_managed?: false, show_only_media_content?: false)
        affiliate.stub_chain(:rss_feeds, :find_by_id).with(feed.id).and_return(feed)

        until_ts = Time.parse('2012-10-31')
        Time.should_receive(:strptime).with('10/31/2012', '%m/%d/%Y').and_return(until_ts.clone)
        news_search = NewsSearch.new(query: 'element', channel: feed.id, affiliate: affiliate, until_date: '10/31/2012')
        ElasticNewsItem.should_receive(:search_for).
          with(q: 'element', rss_feeds: [feed], excluded_urls: affiliate.excluded_urls,
               since: nil, until: until_ts.utc.end_of_day,
               offset: 0, size: 10,
               contributor: nil, subject: nil, publisher: nil,
               sort_by_relevance: false,
               tags: [], language: 'en')

        news_search.run
      end
    end

    context 'when sorting by relevance' do
      it 'should pass in the sort_by param' do
        feed = affiliate.rss_feeds.first
        search = NewsSearch.new(query: 'element', channel: feed.id, affiliate: affiliate,
                                contributor: 'contributor', publisher: 'publisher', subject: 'subject',
                                sort_by: 'r')
        ElasticNewsItem.should_receive(:search_for).
          with(q: 'element', rss_feeds: [feed], excluded_urls: affiliate.excluded_urls,
               since: nil, until: nil,
               offset: 0, size: 10,
               contributor: 'contributor', subject: 'subject', publisher: 'publisher',
               sort_by_relevance: true,
               tags: [], language: 'en')
        search.run.should be_true
      end
    end

    context 'when response is present' do
      it 'should assign the correct start and end record' do
        feed = affiliate.rss_feeds.first
        search = NewsSearch.new(query: 'element', channel: feed.id, affiliate: affiliate, page: 2, per_page: '15')
        response = mock(ElasticNewsItemResults, total: 17, offset: 15, aggregations: [], results: [mock('result1'), mock('result2')])
        ElasticNewsItem.should_receive(:search_for).
          with(q: 'element', rss_feeds: [feed], excluded_urls: affiliate.excluded_urls,
               since: nil, until: nil,
               offset: 15, size: 15,
               contributor: nil, subject: nil, publisher: nil,
               sort_by_relevance: false,
               tags: [], language: 'en').
          and_return(response)

        search.run
        search.startrecord.should == 16
        search.endrecord.should == 17
      end
    end
  end

  describe "#cache_key" do
    let(:options) { { query: 'element', affiliate: affiliate } }
    let(:feed) { rss_feeds(:managed_video) }
    let(:since_a_week_ago) { Date.current.advance(weeks: -1).to_s }

    it "should output a key based on the affiliate id, query, channel, tbs, since-until, page, and per_page parameters" do
      NewsSearch.new(options.merge(tbs: 'w', channel: feed.id, page: 2, per_page: 21)).cache_key.should == "#{affiliate.id}:element:#{feed.id}:#{since_a_week_ago}:2:21"
      NewsSearch.new(options.merge(channel: feed.id)).cache_key.should == "#{affiliate.id}:element:#{feed.id}::1:20"
      NewsSearch.new(options.merge(tbs: 'w')).cache_key.should == "#{affiliate.id}:element::#{since_a_week_ago}:1:10"
      NewsSearch.new(options.merge(since_date: '10/1/2012', until_date: '10/31/2012')).cache_key.should == "#{affiliate.id}:element::2012-10-01..2012-10-31:1:10"
    end
  end
end
