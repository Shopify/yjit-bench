class Stats
  def initialize(data)
    @data = data
  end

  def min
    @data.min
  end

  def max
    @data.max
  end

  def mean
    @data.sum(0.0) / @data.size
  end

  def stddev
    mean = self.mean
    diffs_squared = @data.map { |v| (v-mean) * (v-mean) }
    mean_squared = diffs_squared.sum(0.0) / @data.size
    Math.sqrt(mean_squared)
  end

  def median
    compute_median(@data)
  end

  def median_absolute_deviation(median)
    compute_median(@data.map { |v| (v - median).abs })
  end

  private

  def compute_median(data)
    size = data.size
    sorted = data.sort
    if size.odd?
      sorted[size/2]
    else
      (sorted[size/2-1] + sorted[size/2]) / 2.0
    end
  end
end
