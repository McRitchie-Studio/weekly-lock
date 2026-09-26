require "application_system_test_case"

# E2E tier: a visitor reads the lock, opens a past week, and walks the season.
class WeeklyLockTest < ApplicationSystemTestCase
  test "home to a past week, across to its neighbour, and back" do
    visit root_path
    assert_selector ".brand", text: /the weekly lock/i
    assert_selector "[data-record]", text: "8-3-1"

    within("[data-season]") { click_on "Take the points, keep the game close" }
    assert_current_path week_path(7)
    assert_selector "h1", text: /take the points, keep the game close/i
    assert_selector "[data-result=hit]"

    click_on "Week 8"
    assert_current_path week_path(8)
    assert_selector "[data-result=miss]"

    click_on "All weeks"
    assert_current_path root_path
    assert_selector "[data-this-week] h2", text: /week 13/i
  end

  test "the phone layout keeps the lock and record readable without sideways scroll" do
    page.driver.browser.manage.window.resize_to(390, 844)
    visit root_path
    assert_selector "[data-this-week] [data-pick]", text: "PHI -4"
    scroll_width = page.evaluate_script("document.documentElement.scrollWidth")
    client_width = page.evaluate_script("document.documentElement.clientWidth")
    assert_operator scroll_width, :<=, client_width, "page scrolls sideways on a phone"
  end
end
