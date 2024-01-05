require_relative '../harness/loader'

def nq_solve(n)
	a = Array.new(n) { -1 }
	l = Array.new(n) { 0 }
	c = Array.new(n) { 0 }
	r = Array.new(n) { 0 }
	y0 = (1<<n) - 1
	m = 0
	k = 0
	while k >= 0 do
		y = (l[k] | c[k] | r[k]) & y0
		if (y ^ y0) >> (a[k] + 1) != 0 then
			i = a[k] + 1
			while i < n and (y & 1<<i) != 0 do
				i += 1
			end
			if k < n - 1 then
				z = 1<<i
				a[k] = i
				k += 1
				l[k] = (l[k-1]|z)<<1
				c[k] = c[k-1]|z
				r[k] = (r[k-1]|z)>>1
			else
				m += 1
				k -= 1
			end
		else
			a[k] = -1
			k -= 1
		end
	end
	return m
end

n = 12
if ARGV.length() > 0 then
	n = ARGV[0].to_i
end

run_benchmark(40) do
	nq_solve(n)
end
