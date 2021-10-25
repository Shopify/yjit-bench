# adapted from:
# http://dalibornasevic.com/posts/39-simple-way-to-test-io-in-ruby
class FakeIO

  attr_reader :input, :output

  def initialize(input = [])
    @input = input
    @output = ""
  end

  def gets
    @input.shift.to_s
  end

  def print(string = '')
    @output << string
    nil
  end

  alias_method :write, :print

  def puts(string = '')
    print "#{string}\n"
  end

  def match(regex_or_so)
    @output.match regex_or_so
  end

  def self.each_input(input)
    fake_io = new(input)
    $stdin = fake_io
    $stdout = fake_io

    yield

    fake_io.output
  rescue SystemExit
    # it's cool to exit, it's what we want to do at some point.
    fake_io.output

  ensure
    $stdin = STDIN
    $stdout = STDOUT

  end
end