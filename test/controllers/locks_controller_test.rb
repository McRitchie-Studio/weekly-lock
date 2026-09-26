require "test_helper"

# Component tier: the pages as rendered HTML.
class LocksControllerTest < ActionDispatch::IntegrationTest
  test "/up answers 200 with no database" do
    get rails_health_check_path
    assert_response :success
  end

  test "home leads with this week's lock and the season record" do
    get root_path
    assert_response :success
    assert_select "title", "The Weekly Lock"
    assert_select "[data-this-week]" do
      assert_select "h2", /Week 13/
      assert_select "[data-pick]", /PHI -4/
      assert_select "[data-result=pending]"
      assert_select "a[href=?]", week_path(13)
    end
    assert_select "[data-record]", /8-3-1/
    assert_select "[data-win-rate]", /72.7%/
    assert_select "[data-streak]", /2 straight hits/
  end

  test "home lists every week, newest first, each linking to its page with its result" do
    get root_path
    rows = css_select("[data-season] li[data-week]")
    assert_equal (1..13).to_a.reverse, rows.map { |row| row["data-week"].to_i }
    assert_select "[data-season] li[data-week='3'] [data-result=miss]"
    assert_select "[data-season] li[data-week='5'] [data-result=push]"
    assert_select "[data-season] li[data-week='12'] [data-result=hit]"
    assert_select "[data-season] a[href=?]", week_path(1)
  end

  test "every page says the season is demo data" do
    [ root_path, week_path(1) ].each do |path|
      get path
      assert_select "[data-demo-notice]", /demo/i
    end
  end

  test "a graded week shows the pick, final score, result and write-up, with neighbours" do
    get week_path(7)
    assert_response :success
    assert_select "title", "Week 7: Take the points, keep the game close | The Weekly Lock"
    assert_select "h1", "Take the points, keep the game close"
    assert_select "[data-pick]", /HOU \+3/
    assert_select "[data-matchup]", /Houston Texans at Baltimore Ravens/
    assert_select "[data-final]", /21.*23/m
    assert_select "[data-result=hit]", /Hit/
    assert_select "[data-write-up]", /lose by two or fewer/
    assert_select "a[rel=prev][href=?]", week_path(6)
    assert_select "a[rel=next][href=?]", week_path(8)
  end

  test "the pending week says so and has no final score or next link" do
    get week_path(13)
    assert_select "[data-result=pending]", /Pending/
    assert_select "[data-final]", 0
    assert_select "a[rel=next]", 0
    assert_select "a[rel=prev][href=?]", week_path(12)
  end

  test "week 1 has no previous link" do
    get week_path(1)
    assert_select "a[rel=prev]", 0
  end

  test "an unknown week is a 404" do
    get "/weeks/99"
    assert_response :not_found
    get "/weeks/0"
    assert_response :not_found
  end

  test "pages set no cookie" do
    get root_path
    assert_nil response.headers["set-cookie"]
  end
end
