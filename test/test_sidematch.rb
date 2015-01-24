
require "sidematch"
require "test/unit"
require "stringio"

class TestParallelComparator < Test::Unit::TestCase
  def check_strings(arguments,*tests)
    output = StringIO.new
    comparator = ParallelComparator.new(arguments, output)
    tests.each do |source,target,expected,status|
      exit_status = comparator.compare(StringIO.new(source), StringIO.new(target))
      output.seek(0)
      output_string = output.read
      assert_equal(expected, output_string)
      assert_equal(status, exit_status)
      output.seek(0)
      output.truncate(0)
    end
  end

  GREEN="\033[0;32m"
  RED="\033[1;31m"
  PURPLE="\033[0;35m"
  CLEAR="\033[0m"

  def test_no_color
    check_strings(["-C", "-q"],
                  ["1\n2\n3\n", "1\n2\n4\n", "+ 1 1\n+ 2 2\n- 3 4\n",1],
                  ["1\n2\n3\n", "1\n2\n3\n", "+ 1 1\n+ 2 2\n+ 3 3\n",0],
                  ["1\n2\n3\n", "1\n2\n", "+ 1 1\n+ 2 2\n- 3 EOF\n",1],
                 ) 
  end

  def test_simple
    check_strings(["-c", "-q"],
                  ["1\n2\n3\n", "1\n2\n4\n", "1 #{GREEN}1#{CLEAR}\n2 #{GREEN}2#{CLEAR}\n3 #{RED}4#{CLEAR}\n",1],
                  ["1\n2\n3\n", "1\n2\n3\n", "1 #{GREEN}1#{CLEAR}\n2 #{GREEN}2#{CLEAR}\n3 #{GREEN}3#{CLEAR}\n",0],
                  ["1\n2\n3\n", "1\n2\n", "1 #{GREEN}1#{CLEAR}\n2 #{GREEN}2#{CLEAR}\n3 #{PURPLE}EOF#{CLEAR}\n",1],
                 ) 
  end

  def test_filter
    check_strings(["-c", "-q", "-m"],
                  ["1\n2\n3\n", "1\n2\n4\n", "1 #{GREEN}1#{CLEAR}\n2 #{GREEN}2#{CLEAR}\n",1],
                  ["1\n2\n3\n", "1\n2\n3\n", "1 #{GREEN}1#{CLEAR}\n2 #{GREEN}2#{CLEAR}\n3 #{GREEN}3#{CLEAR}\n",0],
                  ["1\n2\n3\n", "1\n2\n", "1 #{GREEN}1#{CLEAR}\n2 #{GREEN}2#{CLEAR}\n",1],
                 ) 

    check_strings(["-c", "-q", "-M"],
                  ["1\n2\n3\n", "1\n2\n4\n", "3 #{RED}4#{CLEAR}\n",1],
                  ["1\n2\n3\n", "1\n2\n3\n", "",0],
                  ["1\n2\n3\n", "1\n2\n", "3 #{PURPLE}EOF#{CLEAR}\n",1],
                 ) 

  end

end
