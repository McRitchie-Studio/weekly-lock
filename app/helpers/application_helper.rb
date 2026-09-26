module ApplicationHelper
  RESULT_LABELS = { hit: "Hit", miss: "Miss", push: "Push", pending: "Pending" }.freeze

  def result_pill(lock)
    tag.span(RESULT_LABELS.fetch(lock.result), class: "pill pill--#{lock.result}", data: { result: lock.result })
  end

  def team_badge(team, size: nil)
    tag.span(team.abbr, class: [ "badge", ("badge--#{size}" if size) ],
      style: "--team: #{team.color}", title: team.name, aria: { hidden: true })
  end

  def posted_on(lock)
    "Posted #{lock.posted_on.strftime('%A, %B %-d')}"
  end

  # "2 straight hits" / "1 miss in a row"
  def streak_label(streak)
    return "No decisions yet" unless streak

    result, length = streak
    noun = result == :hit ? "hit" : "miss"
    length == 1 ? "Last pick: a #{noun}" : "#{length} straight #{noun.pluralize(length)}"
  end

  def lock_icon
    tag.svg(viewBox: "0 0 24 24", class: "lock-icon", aria: { hidden: true }) do
      tag.rect(x: 4, y: 10, width: 16, height: 11, rx: 2.5) +
        tag.path(d: "M8 10V7a4 4 0 0 1 8 0v3", fill: "none") +
        tag.circle(cx: 12, cy: 15.5, r: 1.6, class: "lock-icon__hole")
    end
  end
end
