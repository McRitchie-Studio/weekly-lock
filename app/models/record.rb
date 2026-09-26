# The running record: hits, misses and pushes against the spread.
Record = Data.define(:hits, :misses, :pushes) do
  def self.tally(results)
    new(hits: results.count(:hit), misses: results.count(:miss), pushes: results.count(:push))
  end

  def to_s = "#{hits}-#{misses}-#{pushes}"

  def decided = hits + misses

  # Percent of decided picks that hit, one decimal; pushes do not count.
  # Nil until a pick has been decided.
  def win_rate
    return nil if decided.zero?

    (hits * 100.0 / decided).round(1)
  end
end
