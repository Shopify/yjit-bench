NUM_LEVELS = 30
FNS_PER_LEVEL = 1000

$out = ""

def addln(str = "")
    $out << str << "\n"
end

NUM_LEVELS.times do |l_no|
    FNS_PER_LEVEL.times do |f_no|
        f_name = "fun_l#{l_no}_n#{f_no}"

        if l_no < NUM_LEVELS - 1
            callee_no1 = rand(0...FNS_PER_LEVEL)
            callee_name1 = "fun_l#{l_no+1}_n#{callee_no1}"
            callee_no2 = rand(0...FNS_PER_LEVEL)
            callee_name2 = "fun_l#{l_no+1}_n#{callee_no2}"
        else
            callee_name1 = "inc"
            callee_name2 = "inc"
        end

        addln("def #{f_name}(x)")
        addln("    if (x < 1)")
        addln("        #{callee_name1}(x)")
        addln("    else")
        addln("        #{callee_name2}(x)")
        addln("    end")
        addln("end")
        addln()
    end
end

addln("@a = 0")
addln("@b = 0")
addln("@c = 0")
addln("@d = 0")
addln("")
addln("@count = 0")
addln("def inc(x)")
addln("    @count += 1")
addln("end")
addln("")
addln("@x = 0")
addln("")

# 100K times
addln("600.times do")
    # Flip the value of x
    addln("    @x = (@x < 1)? 1:0")

    FNS_PER_LEVEL.times do |f_no|
        f_name = "fun_l0_n#{f_no}"
        addln("    #{f_name}(@x)")
    end
addln("end")

addln("puts @count")

puts($out)