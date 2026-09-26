# A season of locks, read from a checked-in YAML file. There is no database:
# the file is the whole store, and the record is computed from its scores.
class Season
  class Invalid < StandardError; end

  PATH = Rails.root.join("data/season-2026.yml")

  attr_reader :year, :locks

  def self.current
    @current ||= load(PATH)
  end

  def self.load(path)
    from_h(YAML.safe_load_file(path, permitted_classes: [ Date ]))
  rescue Errno::ENOENT, Psych::Exception => e
    raise Invalid, "#{path}: #{e.message}"
  end

  def self.from_h(data)
    teams = data.fetch("teams").to_h do |abbr, team|
      [ abbr, Team.new(abbr: abbr, name: team.fetch("name"), color: team.fetch("color")) ]
    end
    locks = data.fetch("weeks").map { |row| build_lock(row, teams) }
    new(year: data.fetch("year"), demo: data.fetch("demo", false), locks: locks)
  rescue KeyError => e
    raise Invalid, e.message
  end

  def self.build_lock(row, teams)
    team_for = ->(key) { teams.fetch(row.fetch(key)) { raise Invalid, "week #{row['week']}: unknown team #{row[key]}" } }
    posted_on = row.fetch("posted_on")
    raise Invalid, "week #{row['week']}: posted_on #{posted_on} is not a Wednesday" unless posted_on.is_a?(Date) && posted_on.wednesday?
    if row["team_score"].nil? != row["opponent_score"].nil?
      raise Invalid, "week #{row['week']}: give both scores or neither"
    end

    Lock.new(
      week: Integer(row.fetch("week")), posted_on: posted_on,
      team: team_for.("team"), opponent: team_for.("opponent"),
      home: row.fetch("home") == true, spread: row.fetch("spread").to_r,
      team_score: row["team_score"], opponent_score: row["opponent_score"],
      headline: row.fetch("headline"), write_up: row.fetch("write_up")
    )
  end
  private_class_method :build_lock

  def initialize(year:, demo:, locks:)
    numbers = locks.map(&:week)
    raise Invalid, "weeks must run 1, 2, 3 ... without gaps (got #{numbers.inspect})" unless numbers == (1..locks.size).to_a

    @year = year
    @demo = demo
    @locks = locks.freeze
  end

  def demo? = @demo

  def find(number) = locks.find { |lock| lock.week == number }

  # The lock on top of the home page: the latest one posted.
  def this_week = locks.last

  def graded = locks.select(&:final?)

  def record = Record.tally(graded.map(&:result))

  # [result, length] of the current run of hits or misses, newest first;
  # pushes neither extend nor break it. Nil before any decision.
  def streak
    decided = graded.map(&:result).reject { |result| result == :push }.reverse
    return nil if decided.empty?

    [ decided.first, decided.take_while { |result| result == decided.first }.size ]
  end
end
