# frozen_string_literal: true

class Sites::QueryDownloadsController < Sites::SetupSiteController
  include CsvResponsive
  MAX_RESULTS = 50_000

  def show
    @end_date = params['end_date'].to_date
    @start_date = params['start_date'].to_date
    filename = [@site.name, @start_date, @end_date].join('_')
    header = [
      'Search Term',
      'Real (Humans only) Queries',
      'Real Clicks',
      'Real CTR',
      'Total (Bots + Humans) Queries',
      'Total Clicks',
      'Total CTR'
    ]
    csv_response(filename, header, top_queries)
  end

  private

  def top_queries
    report_array = query_raw_count_array.map do |query_term, query_raw_count|
      query_human_count = query_human_count_hash[query_term] || 0
      click_raw_count = click_raw_count_hash[query_term] || 0
      click_human_count = click_human_count_hash[query_term] || 0

      ctr_raw = ctr(click_raw_count, query_raw_count)
      ctr_human = ctr(click_human_count, query_human_count)

      [
        query_term,
        query_human_count,
        click_human_count,
        ctr_human,
        query_raw_count,
        click_raw_count,
        ctr_raw
      ]
    end

    report_array.sort_by { |a| -a[1] }
  end

  def ctr(click_count, query_count)
    return '--' if click_count.zero? || query_count.zero?

    sprintf('%.1f%%', click_count.to_f * 100 / query_count)
  end

  def date_range_top_n_query(type)
    DateRangeTopNQuery.new(
      @site.name,
      type,
      @start_date,
      @end_date,
      field: 'params.query.raw',
      size: MAX_RESULTS
    )
  end

  def query_raw_count_array
    @query_raw_count_array ||= begin
      rtu_top_queries = RtuTopQueries.new(date_range_top_n_query('search').body, false)
      rtu_top_queries.top_n
    end
  end

  def query_human_count_hash
    @query_human_count_hash ||= begin
      top_human_queries = RtuTopQueries.new(date_range_top_n_query('search').body, true)
      Hash[top_human_queries.top_n]
    end
  end

  def click_raw_count_hash
    @click_raw_count_hash ||= begin
      top_clicks = RtuTopClicks.new(date_range_top_n_query('click').body, false)
      Hash[top_clicks.top_n]
    end
  end

  def click_human_count_hash
    @click_human_count_hash ||= begin
      top_human_clicks = RtuTopClicks.new(date_range_top_n_query('click').body, true)
      Hash[top_human_clicks.top_n]
    end
  end
end
