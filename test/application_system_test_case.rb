require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  DESKTOP_SIZE = [ 1280, 900 ].freeze
  driven_by :selenium, using: :headless_chrome, screen_size: DESKTOP_SIZE

  # The browser outlives the test, so a window resize leaks into whichever test
  # runs next. Every system test starts at the desktop size the case is driven
  # at (task apps-system-tests-reset-window; the same leak turned
  # commercial-welding red under one seed).
  setup { page.driver.browser.manage.window.resize_to(*DESKTOP_SIZE) }

  # A real phone-width viewport (task system-tests-real-phone-widths).
  # Headless Chrome will not size its window under 500px, so
  # resize_to(390, ...) gives a 500px page and a "390px" check passes at the
  # wrong width. DevTools device-metrics emulation sets the viewport itself.
  # After each visit, and before you measure, call assert_viewport_width.
  # It reads clientWidth, not innerWidth: under mobile emulation innerWidth
  # grows to fit a page that overflows, so a check against it passes
  # vacuously. Use it at phone widths only (mobile emulation overlays the
  # scrollbar; a desktop Linux Chrome takes 15px of clientWidth for one).
  # The driver outlives the test, so every system test clears the override.
  def phone_viewport!(width, height = 844)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
                                    width: width, height: height, deviceScaleFactor: 1, mobile: true)
  end

  def assert_viewport_width(width)
    assert_equal width, evaluate_script("document.documentElement.clientWidth"), "the viewport is #{width}px"
  end

  teardown { page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride") }
end
