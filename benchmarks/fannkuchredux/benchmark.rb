# The Computer Language Benchmarks Game
# https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
# Contributed by Wesley Moxam
# Modified by Sokolov Yura aka funny_falcon

def fannkuch(n)
  p = (0..n).to_a
  s = p.dup
  q = p.dup
  sign = 1
  sum = maxflips = 0
  while(true)
    # flip.
    if (q1 = p[1]) != 1
      q[0..-1] = p
      flips = 1
      until (qq = q[q1]) == 1
        q[q1] = q1
        if q1 >= 4
          i, j = 2, q1 - 1
          while i < j
            q[i], q[j] = q[j], q[i]
            i += 1
            j -= 1
          end
        end
        q1 = qq
        flips += 1
      end
      sum += sign * flips
      maxflips = flips if flips > maxflips # New maximum?
    end
    # Permute.
    if sign == 1
      # Rotate 1<-2.
      p[1], p[2] = p[2], p[1]
      sign = -1
    else
      # Rotate 1<-2 and 1<-2<-3.
      p[2], p[3] = p[3], p[2]
      sign = 1
      i = 3
      while i <= n && s[i] == 1
        return [sum, maxflips] if i == n     # Out of permutations.
        s[i] = i
        # Rotate 1<-...<-i+1.
        t = p.delete_at(1)
        i += 1
        p.insert(i, t)
      end
      s[i] -= 1  if i <= n
    end
  end
end

#n = (ARGV[0] || 1).to_i
N = 9 # Benchmarks Game uses n = 12, but it's too slow

require_relative '../../harness/loader'

run_benchmark(10) do
  sum, flips = fannkuch(N)

  if sum != 8629
    raise RuntimeError, "incorrect sum: #{sum}"
  end

  if flips != 30
    raise RuntimeError, "incorrect flips: #{flips}"
  end
end
