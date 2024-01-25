require_relative '../harness/loader'

# XOR strings in place
# Expected to behave like Xorcist.xor! from the xorcist gem
# https://github.com/fny/xorcist/tree/master
#
# This is a test of the performance of low-level operations in Ruby,
# it is written to try and get the maximum possible performance with YJIT,
# it is not trying to look like idiomatic Ruby code.
#
def ruby_xor!(a, b)
    if !a.is_a? String or !b.is_a? String
        raise 'expected two string arguments'
    end

    l = a.bytesize
    lb = b.bytesize
    if lb < l
        l = lb
    end

    i = 0
    while i < l
        ba = a.getbyte(i)
        bb = b.getbyte(i)
        a.setbyte(i, ba ^ bb)
        i += 1
    end

    a
end

a = 'this is a long string with no useful contents yada yada yada yada'
b = 'this is also a long string with no useful contents yada yada daaaaaa'

run_benchmark(20) do
    for i in 0...100_000
        ruby_xor!(a.dup, b)
    end
end
