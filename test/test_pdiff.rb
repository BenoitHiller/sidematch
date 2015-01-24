
require_relative "../pdiff"
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

  def test_no_color
    check_strings(["-C"],
                  ["1\n2\n3\n", "1\n2\n4\n", "+ 1 1\n+ 2 2\n- 3 4\n",1],
                  ["1\n2\n3\n", "1\n2\n3\n", "+ 1 1\n+ 2 2\n+ 3 3\n",0],
                  ["1\n2\n3\n", "1\n2\n", "+ 1 1\n+ 2 2\n- 3 EOF\n",1],
                 ) 
  end
end
