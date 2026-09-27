# One week's lock: the team we took, the line, and (once final) the score.
Lock = Data.define(:week, :posted_on, :team, :opponent, :home, :spread,
                   :team_score, :opponent_score, :headline, :write_up) do
  # Posted on a Wednesday; Sunday's games and Monday night's are over by
  # the Tuesday after, so the week is graded from then.
  GRADED_AFTER_DAYS = 6

  def final? = !team_score.nil?

  def graded_by?(date) = date >= posted_on + GRADED_AFTER_DAYS

  # Against the spread: the team's score plus the line, compared with the
  # opponent's. Above covers (a hit), level is a push, below is a miss.
  def result
    return :pending unless final?

    case (team_score + spread) <=> opponent_score
    when 1 then :hit
    when 0 then :push
    else :miss
    end
  end

  # "-3.5", "+3", or "PK" for a pick'em.
  def line
    return "PK" if spread.zero?

    number = spread.denominator == 1 ? spread.to_i : spread.to_f
    spread.positive? ? "+#{number}" : number.to_s
  end

  def pick = "#{team.abbr} #{line}"

  def matchup = "#{team.abbr} #{home ? 'vs' : 'at'} #{opponent.abbr}"

  def matchup_long = "#{team.name} #{home ? 'vs' : 'at'} #{opponent.name}"

  def final_score = "#{team.abbr} #{team_score}, #{opponent.abbr} #{opponent_score}"
end
