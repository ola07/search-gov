# frozen_string_literal: true

class AffiliateCss
  include AffiliateCssHelper

  MOBILE_LOOK_AND_FEEL_TEMPLATE = Rails.root.join('lib/renderers/templates/_mobile_look_and_feel.css.sass.erb').read.freeze

  def initialize(css_hash)
    @css_hash = css_hash.freeze
  end

  def render_mobile_css
    render_css(render_sass_template(ERB.new(MOBILE_LOOK_AND_FEEL_TEMPLATE, trim_mode: '<>')))
  end

  private

  def render_sass_template(template)
    template.result(binding)
  end

  def render_css(sass_template)
    SassTemplate.new(sass_template).render
  end
end
