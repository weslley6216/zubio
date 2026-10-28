class Components::Owner::Appointments::ClientSearch < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  FRAME_ID = "client-search-results".freeze
  MATCH_LABEL = "já é sua cliente".freeze
  NEW_CLIENT_LABEL = "Cliente nova com este telefone".freeze

  CARD_CLASS = "rounded-xl border border-line bg-surface overflow-hidden".freeze
  MATCH_ROW_CLASS = "flex w-full items-center gap-3 bg-brand-100 px-4 py-3 text-left".freeze
  AVATAR_CLASS = "grid h-9 w-9 flex-none place-items-center rounded-full bg-surface text-[13px] font-extrabold text-brand-800".freeze
  TEXT_CLASS = "flex min-w-0 flex-grow flex-col gap-0.5".freeze
  NAME_CLASS = "text-[14px] font-bold text-brand-800".freeze
  SUB_CLASS = "text-[12px] text-brand-800".freeze
  CHECK_ICON_CLASS = "h-5 w-5 flex-none text-brand-600".freeze
  NEW_ROW_CLASS = "flex w-full items-center gap-2 border-t border-line px-4 py-3 text-[14px] font-bold text-brand-600".freeze
  PLUS_ICON_CLASS = "h-5 w-5 flex-none".freeze

  def initialize(matches:, query:)
    @matches = matches
    @query = query
  end

  def view_template
    turbo_frame_tag(FRAME_ID, class: "contents", data: { client_search_target: "results" }) do
      div(data: { busy_fade: true }) { render_results } if @query.present?
    end
  end

  private

  def render_results
    div(class: CARD_CLASS) do
      @matches.each { |client| render_match(client) }
      render_new_client_row
    end
  end

  def render_match(client)
    button(type: "button", class: MATCH_ROW_CLASS, aria_pressed: "false", data: {
      client_search_match: true, action: "client-search#choose",
      client_id: client.id, client_name: client.name, client_phone: client.phone_display
    }) do
      span(class: AVATAR_CLASS) { client.initials }
      div(class: TEXT_CLASS) do
        span(class: NAME_CLASS) { client.name }
        span(class: SUB_CLASS) { "#{client.phone_display} · #{MATCH_LABEL}" }
      end
      render_check_icon
    end
  end

  def render_check_icon
    render Components::Icon.new(:check, stroke_width: "2.6", class: CHECK_ICON_CLASS)
  end

  def render_new_client_row
    button(type: "button", class: NEW_ROW_CLASS, data: { action: "client-search#chooseNew" }) do
      render_plus_icon
      plain NEW_CLIENT_LABEL
    end
  end

  def render_plus_icon
    render Components::Icon.new(:plus, class: PLUS_ICON_CLASS)
  end
end
