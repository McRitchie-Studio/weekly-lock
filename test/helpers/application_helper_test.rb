require "test_helper"

# Unit tier: badge text stays readable on every team color.
class ApplicationHelperTest < ActionView::TestCase
  test "badge text is white on dark team colors and near-black where white fails AA" do
    assert_equal "#fff", badge_ink("#241773")
    assert_equal "#fff", badge_ink("#000000")
    assert_equal "#111", badge_ink("#FB4F14")
  end

  test "every checked-in team's badge text reaches 4.5:1" do
    Season.current.locks.flat_map { |lock| [ lock.team, lock.opponent ] }.uniq.each do |team|
      ratio = contrast(team.color, badge_ink(team.color))
      assert_operator ratio, :>=, 4.5, "#{team.abbr} #{team.color}: #{ratio.round(2)}:1"
    end
  end

  private

  def contrast(a, b)
    la, lb = [ a, b ].map { |hex| luminance(hex) }.sort.reverse
    (la + 0.05) / (lb + 0.05)
  end

  def luminance(hex)
    hex = hex.delete_prefix("#")
    hex = hex.chars.map { |c| c * 2 }.join if hex.size == 3
    r, g, b = hex.scan(/../).map do |pair|
      c = pair.hex / 255.0
      c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4
    end
    0.2126 * r + 0.7152 * g + 0.0722 * b
  end
end
