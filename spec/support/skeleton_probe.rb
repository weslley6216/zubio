module SkeletonProbe
  def watch_skeleton(frame_id)
    page.execute_script(<<~JS)
      window.__skeletonPeak = 0
      const frame = document.getElementById(#{frame_id.to_json})
      const tick = () => {
        const skeleton = frame.querySelector("[data-skeleton]")
        if (skeleton) {
          const value = parseFloat(getComputedStyle(skeleton).opacity)
          if (value > window.__skeletonPeak) window.__skeletonPeak = value
        }
        window.__skeletonRAF = requestAnimationFrame(tick)
      }
      tick()
    JS
  end

  def skeleton_peak
    page.evaluate_script("window.__skeletonPeak")
  end
end

RSpec.configure do |config|
  config.include SkeletonProbe, type: :system
end
