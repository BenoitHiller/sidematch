#!/usr/bin/env ruby

require 'optparse'
require 'set'

class ParallelComparator

  GREEN="\033[0;32m"
  RED="\033[1;31m"
  PURPLE="\033[0;35m"
  CLEAR="\033[0m"

  def initialize(args,output=$stdout)
    @output = output
    if output.tty?
      @color = true
    end
    ordered_args = parse_options(args)
  end

  def parse_options(args)
    @ifs = $/
    @ofs = $/
    @tab = " "
    @print_matches = true
    @print_failures = true
    @silent = false
    @quiet = false
    @line_numbers = false
    # parse options out of ARGV
    OptionParser.new do |opts|
      opts.banner += " source_file [target_file]"
      opts.version = "0.5"

      opts.on("-m", "--matches", "Only print matches") do
        unless @print_matches
          $stderr.puts "Invalid options, -m and -M are mutually exclusive"
          exit 5
        end
        
        @print_failures = false
      end

      opts.on("-M", "--no-matches", "Only print failures") do
        unless @print_failures
          $stderr.puts "Invalid options, -m and -M are mutually exclusive"
          exit 5
        end
        
        @print_matches = false
      end

      opts.on("-q", "--quiet", "Do not print details to stderr") do
        @quiet = true
      end

      opts.on("-s", "--silent", "Do not print anything at all.") do
        @quiet = true
        @silent = true
      end

      opts.on("-0", "Use null as the input and output delimeter.", "  This will be superceeded by -d or -D") do
        @ifs = "\0"
        @ofs = "\0"
      end

      opts.on("-d delimeter", "Input delimeter. By default this is a newline.") do |separator|
        @ifs[:separator] = separator
      end

      opts.on("-D delimeter", "Output delimeter. By default this is a newline.") do |separator|
        @ofs = separator
      end

      opts.on("-l", "--line-numbers", "Print line numbers at the start of each line.") do
        @line_numbers = true
      end

      opts.on("-T column_delimeter", "Specify the characters to separate the columns with.", "  The default is a single space.") do |tab|
          @tab = tab
      end

      opts.on("-t", "Delimit columns with a tab. Equivalent to \"-T \\t\".") do |tab|
          @tab = "\t"
      end

      opts.on("-c", "Force color output") do 
        @color = true
      end

      opts.on("-C", "Disable color output.") do 
        @color = false
      end

      begin 
        opts.order!(args)
        return args
      rescue OptionParser::ParseError => error
        $stderr.puts error
        $stderr.puts "-h or --help will show valid options"
        exit 5
      end

    end

  end

  def open(source, target=nil)
    unless source.is_a? String
      source_file = source
    else
      unless File.file? source
        $stderr.puts "The file \"" +  source + "\" was not found."
        exit 6
      end

      source_file = File.open(source)
    end

    if target.nil? || target == "-"
      target_file = $stdin
    elsif !target.is_a? String
      target_file = target
    else
      unless File.file? target
        $stderr.puts "The file \"" + target + "\" was not found."
        exit 6
      end

      @check_file = File.open(target)
    end

    return [source_file,target_file]
  end

  def get_formatted(left, right, failed, line, eof=false)
    parts = []
    
    unless @color
      parts << (failed ? "-" : "+")
    end

    if @line_numbers
      parts << line
    end
    
    parts << left

    if eof 
      parts << color(right, PURPLE)
    else
      parts << color(right, (failed ? RED : GREEN))
    end

    return parts.join(@tab)
  end

  def color(string, color)
    if @color
      color + string + CLEAR
    else
      string
    end
  end

  def compare(source, target=nil)
    source_file, target_file = open(source, target)
    
    line_number = 0
    failures = 0
    too_short = false
    too_long = false

    while left = source_file.gets(@ifs)
      failed = false
      line_number += 1
      left = left[0..(-(@ifs.length+1))]
      right = target_file.gets(@ifs)
      unless right.nil?
        right = right[0..(-(@ifs.length+1))]
        if left != right
          failed = true
          failures += 1
        end
      else 
        if !@silent && @print_failures
          @output.printf("%s%s", 
            get_formatted(left, "EOF", true, line_number, true),
            @ofs)
        end
        too_short = true
        break
      end

      unless @silent
        if (failed && @print_failures) || (!failed && @print_matches)
          @output.printf("%s%s",
            get_formatted(left, right, failed, line_number),
            @ofs)
        end
      end
    end

    if too_short
      remaining = source_file.readlines(@ifs).count
      unless @quiet
        $stderr.puts "The test input was #{remaining + 1} line#{remaining > 0 ? "s" : ""} too short."
      end
    else
      remaining = target_file.readlines(@ifs).count
      if remaining > 0
        too_long = true
        unless @quiet
          $stderr.puts "The test input was #{remaining} line#{remaining > 1 ? "s" : ""} longer than expected."
        end
      end
    end

    if failures > 0 || too_short
      return 1
    elsif too_long
      #TODO add flag to ignore this
      return 3
    else
      return 0
    end

    if target_file != $stdin
      target_file.close
    end
    source_file.close
  end

end

