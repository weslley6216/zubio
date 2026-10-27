# frozen_string_literal: true

class Views::Base < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::Flash

  SUBMIT_LOCK_ACTIONS = "submit->submit-lock#lock pageshow@window->submit-lock#unlock".freeze

  def cache_store = Rails.cache
end
