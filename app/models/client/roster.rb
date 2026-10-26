class Client::Roster
  Entry = Data.define(:client, :next_visit_at, :last_visit_at, :visit_count)

  NEXT_VISIT = "CASE WHEN appointments.status = 'confirmed' AND appointments.starts_at >= :now THEN appointments.starts_at END".freeze
  PAST_VISIT = "CASE WHEN appointments.status NOT IN ('cancelled', 'no_show') AND appointments.starts_at < :now THEN appointments.starts_at END".freeze
  AGGREGATES = "clients.*, MIN(#{NEXT_VISIT}) AS next_visit_at, MAX(#{PAST_VISIT}) AS last_visit_at, COUNT(#{PAST_VISIT}) AS visit_count".freeze
  ORDERING = "MIN(#{NEXT_VISIT}) ASC NULLS LAST, MAX(#{PAST_VISIT}) DESC NULLS LAST, clients.name ASC".freeze
  APPOINTMENTS_JOIN = "LEFT JOIN appointments ON appointments.client_id = clients.id AND appointments.tenant_id = :tenant_id".freeze

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
      .select(sanitize(AGGREGATES, now: @now))
      .joins(sanitize(APPOINTMENTS_JOIN, tenant_id: ActsAsTenant.current_tenant.id))
      .group("clients.id")
      .order(Arel.sql(sanitize(ORDERING, now: @now)))

    filter.empty? ? relation : relation.where(*filter)
  end

  def sanitize(sql, binds) = ActiveRecord::Base.sanitize_sql_array([ sql, binds ])

  def filter
    return [] if @query.blank?
    return [ "clients.name ILIKE ?", "%#{@query}%" ] if @query.match?(/[[:alpha:]]/)

    digits = Client.normalize(@query)
    [ "clients.phone LIKE ?", "%#{digits.presence || @query}%" ]
  end
end
