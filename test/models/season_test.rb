require "test_helper"

# Unit tier: the season file and the record computed from it.
class SeasonTest < ActiveSupport::TestCase
  TEAMS = {
    "AAA" => { "name" => "Alpha", "color" => "#111111" },
    "BBB" => { "name" => "Bravo", "color" => "#222222" }
  }.freeze

  # A week of the smallest valid shape; scores nil means pending.
  def week(number, spread:, us: nil, them: nil, posted_on: nil)
    {
      "week" => number,
      "posted_on" => posted_on || (Date.new(2026, 9, 9) + (number - 1) * 7),
      "team" => "AAA", "opponent" => "BBB", "home" => true,
      "spread" => spread, "team_score" => us, "opponent_score" => them,
      "headline" => "Week #{number}", "write_up" => "Because."
    }
  end

  def season(*weeks)
    Season.from_h("year" => 2026, "demo" => true, "teams" => TEAMS, "weeks" => weeks)
  end

  test "the checked-in 2026 season loads, is labelled demo, and runs week 1 upward" do
    s = Season.current
    assert_equal 2026, s.year
    assert s.demo?
    assert_equal (1..s.locks.size).to_a, s.locks.map(&:week)
  end

  test "every checked-in lock is posted on a Wednesday and names known teams" do
    Season.current.locks.each do |lock|
      assert lock.posted_on.wednesday?, "week #{lock.week} posted on #{lock.posted_on.strftime('%A')}"
      assert lock.team.name.present?
      assert lock.opponent.name.present?
      assert lock.write_up.present?
    end
  end

  test "the checked-in record is computed from the scores: 8-3-1" do
    record = Season.current.record
    assert_equal [ 8, 3, 1 ], [ record.hits, record.misses, record.pushes ]
    assert_equal "8-3-1", record.to_s
    assert_in_delta 72.7, record.win_rate, 0.05
  end

  test "a favorite covers only by beating the spread; landing on it is a push" do
    assert_equal :hit,  season(week(1, spread: -3.5, us: 24, them: 20)).locks.first.result
    assert_equal :miss, season(week(1, spread: -3.5, us: 23, them: 20)).locks.first.result
    assert_equal :push, season(week(1, spread: -3, us: 23, them: 20)).locks.first.result
  end

  test "an underdog covers by losing by less than the points" do
    assert_equal :hit,  season(week(1, spread: 3, us: 21, them: 23)).locks.first.result
    assert_equal :push, season(week(1, spread: 3, us: 20, them: 23)).locks.first.result
    assert_equal :miss, season(week(1, spread: 3, us: 17, them: 23)).locks.first.result
  end

  test "a week without a final score is pending and stays out of the record" do
    s = season(week(1, spread: -3, us: 30, them: 10), week(2, spread: -3))
    assert_equal :pending, s.locks.last.result
    assert_equal "1-0-0", s.record.to_s
    assert_equal s.locks.last, s.this_week
  end

  test "this week is the latest lock even when every week is graded" do
    s = season(week(1, spread: -3, us: 30, them: 10), week(2, spread: -3, us: 0, them: 10))
    assert_equal 2, s.this_week.week
  end

  test "win rate ignores pushes and is nil before any decision" do
    s = season(week(1, spread: -3, us: 30, them: 10), week(2, spread: -3, us: 13, them: 10), week(3, spread: -3, us: 0, them: 10))
    assert_in_delta 50.0, s.record.win_rate
    assert_nil season(week(1, spread: -3)).record.win_rate
  end

  test "the streak counts back from the latest graded week, skipping pushes" do
    s = season(
      week(1, spread: -3, us: 0, them: 10),
      week(2, spread: -3, us: 30, them: 10),
      week(3, spread: -3, us: 13, them: 10),
      week(4, spread: -3, us: 30, them: 10),
      week(5, spread: -3)
    )
    assert_equal [ :hit, 2 ], s.streak
    assert_equal [ :hit, 2 ], Season.current.streak
    assert_nil season(week(1, spread: -3)).streak
  end

  test "as of a date, only locks posted by then show, and a score only from the Tuesday after" do
    s = season(week(1, spread: -3, us: 30, them: 10), week(2, spread: -3, us: 30, them: 10), week(3, spread: -3, us: 0, them: 10))
    # Week 2 posts 2026-09-16; its games are over by Tuesday 2026-09-22.
    monday = s.as_of(Date.new(2026, 9, 21))
    assert_equal [ 1, 2 ], monday.locks.map(&:week)
    assert_equal :pending, monday.this_week.result
    assert_equal "1-0-0", monday.record.to_s

    tuesday = s.as_of(Date.new(2026, 9, 22))
    assert_equal :hit, tuesday.this_week.result
    assert_equal "2-0-0", tuesday.record.to_s

    assert_equal 3, s.as_of(Date.new(2026, 9, 23)).this_week.week
    assert_equal s.locks, s.as_of(Date.new(2027, 1, 1)).locks
  end

  test "as of a date before the first lock, the season is empty but still demo" do
    early = season(week(1, spread: -3, us: 30, them: 10)).as_of(Date.new(2026, 9, 8))
    assert_empty early.locks
    assert_nil early.this_week
    assert_equal "0-0-0", early.record.to_s
    assert_nil early.streak
    assert early.demo?
  end

  test "find returns the week or nil" do
    s = season(week(1, spread: -3), week(2, spread: -3))
    assert_equal 2, s.find(2).week
    assert_nil s.find(3)
  end

  test "the line reads -3.5, +3 or PK and the matchup says vs at home, at away" do
    s = season(week(1, spread: -3.5), week(2, spread: 3).merge("home" => false), week(3, spread: 0))
    assert_equal [ "-3.5", "+3", "PK" ], s.locks.map(&:line)
    assert_equal "AAA vs BBB", s.locks.first.matchup
    assert_equal "AAA at BBB", s.locks.second.matchup
  end

  test "a bad file refuses to load: unknown team, gap in weeks, one score, not a Wednesday" do
    assert_raises(Season::Invalid) { season(week(1, spread: -3).merge("team" => "ZZZ")) }
    assert_raises(Season::Invalid) { season(week(1, spread: -3), week(3, spread: -3)) }
    assert_raises(Season::Invalid) { season(week(1, spread: -3, us: 10)) }
    assert_raises(Season::Invalid) { season(week(1, spread: -3, posted_on: Date.new(2026, 9, 10))) }
  end
end
