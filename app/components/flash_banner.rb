class Components::FlashBanner < Components::Base
  include Phlex::Rails::Helpers::Flash

  TONES = { "notice" => :success, "alert" => :danger }.freeze

  def initialize(container_class:)
    @container_class = container_class
  end

  def view_template
    messages = TONES.filter_map { |key, tone| [ flash[key], tone ] if flash[key].present? }
    return if messages.empty?

    div(role: "status", class: @container_class) do
      messages.each { |text, tone| render Components::Alert.new(text: text, tone: tone) }
    end
  end
end
