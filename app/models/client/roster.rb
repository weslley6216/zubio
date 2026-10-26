class Client::Roster
  Entry = Data.define(:client, :next_visit_at, :last_visit_at, :visit_count)

  def initialize(query: nil)
    @query = query.to_s.strip
    @now = Time.current
  end

  def entries
    rows.map do |client|
      Entry.new(
        client: client,
        next_visit_at: client[:next_visit_at]&.in_time_zone,
        last_visit_at: client[:last_visit_at]&.in_time_zone,
        visit_count: client[:visit_count].to_i
      )
    end
  end

  private

  def rows
    relation = Client
      .select(
        "clients.*",
        "MIN(#{next_case}) AS next_visit_at",
        "MAX(#{visit_case}) AS last_visit_at",
        "COUNT(#{visit_case}) AS visit_count"
      )
      .joins(appointments_join)
      .group("clients.id")
      .order(Arel.sql("MIN(#{next_case}) ASC NULLS LAST, MAX(#{visit_case}) DESC NULLS LAST, clients.name ASC"))

    filter.empty? ? relation : relation.where(*filter)
  end

  def appointments_join
    ActiveRecord::Base.sanitize_sql_array([
      "LEFT JOIN appointments ON appointments.client_id = clients.id AND appointments.tenant_id = ?",
      ActsAsTenant.current_tenant.id
    ])
  end

  def next_case
    @next_case ||= ActiveRecord::Base.sanitize_sql_array([
      "CASE WHEN appointments.status = 'confirmed' AND appointments.starts_at >= ? THEN appointments.starts_at END", @now
    ])
  end

  def visit_case
    @visit_case ||= ActiveRecord::Base.sanitize_sql_array([
      "CASE WHEN appointments.status NOT IN ('cancelled', 'no_show') AND appointments.starts_at < ? THEN appointments.starts_at END", @now
    ])
  end

  def filter
    return [] if @query.blank?
    return [ "clients.name ILIKE ?", "%#{@query}%" ] if @query.match?(/[[:alpha:]]/)

    digits = Client.normalize(@query)
    [ "clients.phone LIKE ?", "%#{digits.presence || @query}%" ]
  end
end
