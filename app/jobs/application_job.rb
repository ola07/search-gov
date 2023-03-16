# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  before_perform { Rails.logger.debug("ENVIRONMENTAL VARIABLES: #{ENV.to_hash}") }
end
