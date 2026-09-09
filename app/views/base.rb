# frozen_string_literal: true

class Views::Base < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::Flash

  def cache_store = Rails.cache
end
