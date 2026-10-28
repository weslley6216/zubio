class Components::Icon < Components::Base
  CATALOG = {
    chevron_left: [ [ :path, { d: "m15 18-6-6 6-6" } ] ],
    chevron_right: [ [ :path, { d: "m9 18 6-6-6-6" } ] ],
    chevron_down: [ [ :path, { d: "m6 9 6 6 6-6" } ] ],
    plus: [ [ :path, { d: "M5 12h14" } ], [ :path, { d: "M12 5v14" } ] ],
    minus: [ [ :path, { d: "M5 12h14" } ] ],
    x: [ [ :path, { d: "M18 6 6 18" } ], [ :path, { d: "m6 6 12 12" } ] ],
    check: [ [ :path, { d: "M20 6 9 17l-5-5" } ] ],
    clock: [ [ :circle, { cx: "12", cy: "12", r: "10" } ], [ :path, { d: "M12 6v6l4 2" } ] ],
    calendar: [ [ :path, { d: "M8 2v3" } ], [ :path, { d: "M16 2v3" } ], [ :rect, { x: "3", y: "3", width: "18", height: "18", rx: "2" } ], [ :path, { d: "M3 9h18" } ] ],
    search: [ [ :path, { d: "m21 21-4.34-4.34" } ], [ :circle, { cx: "11", cy: "11", r: "8" } ] ],
    mail: [ [ :path, { d: "m22 7-8.991 5.727a2 2 0 0 1-2.009 0L2 7" } ], [ :rect, { x: "2", y: "4", width: "20", height: "16", rx: "2" } ] ],
    copy: [ [ :rect, { width: "14", height: "14", x: "8", y: "8", rx: "2", ry: "2" } ], [ :path, { d: "M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" } ] ],
    link: [ [ :path, { d: "M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71" } ], [ :path, { d: "M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71" } ] ],
    share: [ [ :path, { d: "M12 2v13" } ], [ :path, { d: "m16 6-4-4-4 4" } ], [ :path, { d: "M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" } ] ],
    arrow_down_to_line: [ [ :path, { d: "M12 17V3" } ], [ :path, { d: "m6 11 6 6 6-6" } ], [ :path, { d: "M19 21H5" } ] ],
    pen_line: [ [ :path, { d: "M13 21h8" } ], [ :path, { d: "M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z" } ] ],
    log_out: [ [ :path, { d: "m16 17 5-5-5-5" } ], [ :path, { d: "M21 12H9" } ], [ :path, { d: "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" } ] ],
    menu: [ [ :path, { d: "M4 5h16" } ], [ :path, { d: "M4 12h16" } ], [ :path, { d: "M4 19h16" } ] ],
    settings: [ [ :path, { d: "M9.671 4.136a2.34 2.34 0 0 1 4.659 0 2.34 2.34 0 0 0 3.319 1.915 2.34 2.34 0 0 1 2.33 4.033 2.34 2.34 0 0 0 0 3.831 2.34 2.34 0 0 1-2.33 4.033 2.34 2.34 0 0 0-3.319 1.915 2.34 2.34 0 0 1-4.659 0 2.34 2.34 0 0 0-3.32-1.915 2.34 2.34 0 0 1-2.33-4.033 2.34 2.34 0 0 0 0-3.831A2.34 2.34 0 0 1 6.35 6.051a2.34 2.34 0 0 0 3.319-1.915" } ], [ :circle, { cx: "12", cy: "12", r: "3" } ] ],
    users: [ [ :path, { d: "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" } ], [ :path, { d: "M16 3.128a4 4 0 0 1 0 7.744" } ], [ :path, { d: "M22 21v-2a4 4 0 0 0-3-3.87" } ], [ :circle, { cx: "9", cy: "7", r: "4" } ] ],
    trash: [ [ :path, { d: "M10 11v6" } ], [ :path, { d: "M14 11v6" } ], [ :path, { d: "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6" } ], [ :path, { d: "M3 6h18" } ], [ :path, { d: "M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" } ] ],
    phone: [ [ :path, { d: "M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384" } ] ],
    message_circle: [ [ :path, { d: "M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092 10 10 0 1 0-4.777-4.719" } ] ],
    circle_alert: [ [ :circle, { cx: "12", cy: "12", r: "10" } ], [ :line, { x1: "12", x2: "12", y1: "8", y2: "12" } ], [ :line, { x1: "12", x2: "12.01", y1: "16", y2: "16" } ] ],
    circle_check: [ [ :circle, { cx: "12", cy: "12", r: "10" } ], [ :path, { d: "m16 9-5.5 5.5L8 12" } ] ],
    info: [ [ :circle, { cx: "12", cy: "12", r: "10" } ], [ :path, { d: "M12 16v-4" } ], [ :path, { d: "M12 8h.01" } ] ],
    square_plus: [ [ :rect, { width: "18", height: "18", x: "3", y: "3", rx: "2" } ], [ :path, { d: "M8 12h8" } ], [ :path, { d: "M12 8v8" } ] ]
  }.freeze

  def initialize(name, stroke_width: "2", **attributes)
    @name = name
    @stroke_width = stroke_width
    @attributes = attributes
  end

  def view_template
    svg(
      viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
      stroke_width: @stroke_width, stroke_linecap: "round", stroke_linejoin: "round",
      aria_hidden: "true", data: { icon: @name.to_s.tr("_", "-") }, **@attributes
    ) do |svg_icon|
      CATALOG.fetch(@name).each { |element, attributes| svg_icon.public_send(element, **attributes) }
    end
  end
end
