module Components::DayPill
  SCROLLER = "flex snap-x snap-mandatory gap-2 overflow-x-auto overscroll-x-contain [scrollbar-width:none] [&::-webkit-scrollbar]:hidden".freeze
  STRIP = "#{SCROLLER} sm:grid sm:grid-cols-7 sm:overflow-visible".freeze
  ITEM = "flex shrink-0 basis-[calc((100%-1.5rem)/4)] snap-start".freeze
  WEEK_ITEM = "#{ITEM} lg:basis-[calc((100%-3rem)/7)]".freeze
  FRAME = "flex-col items-center gap-px rounded-xl py-3".freeze
  SELECTED = "bg-brand-600 text-on-brand shadow-[0_2px_6px_color-mix(in_srgb,var(--brand-600)_20%,transparent)]".freeze
  RESTING = "border border-line bg-surface".freeze
  DISABLED = "border border-dashed border-line-strong bg-surface-2 text-ink-subtle".freeze
  WEEKDAY = "text-[10px] font-bold tracking-[0.04em]".freeze
  WEEKDAY_RESTING = "text-ink-muted".freeze
  NUMBER = "text-[20px] leading-[1.15] font-extrabold tabular-nums".freeze
end
