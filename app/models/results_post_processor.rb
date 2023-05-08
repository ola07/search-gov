# frozen_string_literal: true

class ResultsPostProcessor
  def initialize(*args); end

  def total_pages(total_results)
    pages = total_results.to_i / 20
    pages += 1 if (total_results.to_i % 20).positive?
    pages
  rescue
    0
  end
end
