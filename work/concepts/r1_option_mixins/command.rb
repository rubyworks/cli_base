# = Command
#
# == Copyright (c) 2005 Thomas Sawyer
#
#   Ruby License
#
#   This module is free software. You may use, modify, and/or
#   redistribute this software under the same terms as Ruby.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.
#
# == Author(s)
#
#   CREDIT Thomas Sawyer
#   CREDIT Tyler Rick
#
# == Developer Notes
#
#   TODO Add help/documentation features.
#
#   TODO Problem wiht exit -1 when testing. See IMPORTANT!!! remark below.

require 'shellwords'

# = Console Namespace

module Console; end

# = Command
#
# Command provides a clean and easy way to create a command
# line interface for your program. The unique technique
# utlizes a Commandline to Object Mapping (COM) to make
# it quick and easy.
#
# == Synopsis
#
# Let's make an executable called 'mycmd'.
#
#   #!/usr/bin/env ruby
#
#   require 'facets/console/command'
#
#   class MyCmd < Console::Command
#
#     def _v
#       $VERBOSE = true
#     end
#
#     def jump
#       if $VERBOSE
#         puts "JUMP! JUMP! JUMP!"
#       else
#         puts "Jump"
#       end
#     end
#
#   end
#
#   MyCmd.execute
#
# Then on the command line:
#
#   % mycmd jump
#   Jump
#
#   % mycmd -v jump
#   JUMP! JUMP! JUMP!
#
# == Subcommands
#
# Commands can take subcommand and suboptions. To do this
# simply add a module to your class with the same name
# as the subcommand, in which the suboption methods are defined.
#
#   MyCmd << Console::Command
#
#     def initialize
#       @height = 1
#     end
#
#     def _v
#       $VERBOSE = true
#     end
#
#     def jump
#       if $VERBOSE
#         puts "JUMP!" * @height
#       else
#         puts "Jump" * @height
#       end
#     end
#
#     module Jump
#       def __height(h)
#         @height = h.to_i
#       end
#     end
#
#   end
#
#   MyCmd.start
#
# Then on the command line:
#
#   % mycmd jump -h 2
#   Jump Jump
#
#   % mycmd -v jump -h 3
#   JUMP! JUMP! JUMP!
#
# Another thing to notice about this example is that #start is an alias
# for #execute.
#
# == Missing Subcommands
#
# You can use #method_missing to catch missing subcommand calls.
#
# == Main and Default
#
# If your command does not take subcommands then simply define
# a #main method to dispatch action. All options will be treated globablly
# in this case and any remaining comman-line arguments will be passed
# to #main.
#
# If on the other hand your command does take subcommands but none is given,
# the #default method will be called, if defined. If not defined
# an error will be raised (but only reported if $DEBUG is true).
#
# == Global Options
#
# You can define <i>global options</i> which are options that will be
# processed no matter where they occur in the command line. In the above
# examples only the options occuring before the subcommand are processed
# globally. Anything occuring after the subcommand belonds strictly to
# the subcommand. For instance, if we had added the following to the above
# example:
#
#   global_option :_v
#
# Then -v could appear anywhere in the command line, even on the end,
# and still work as expected.
#
#   % mycmd jump -h 3 -v
#
# == Missing Options
#
# You can use #option_missing to catch any options that are not explicility
# defined.
#
# The method signature should look like:
#
#   option_missing(option_name, args)
#
# Example:
#   def option_missing(option_name, args)
#     p args if $debug
#     case option_name
#       when 'p'
#         @a = args[0].to_i
#         @b = args[1].to_i
#         2
#       else
#         raise InvalidOptionError(option_name, args)
#     end
#   end
#
# Its return value should be the effective "arity" of that options -- that is,
# how many arguments it consumed ("-p a b", for example, would consume 2 args:
# "a" and "b"). An arity of 1 is assumed if nil or false is returned.
#
# Be aware that when using subcommand modules, the same option_missing
# method will catch missing options for global options and subcommand
# options too unless an option_missing method is also defined in the
# subcommand module.
#
#--
#
# == Help Documentation
#
# You can also add help information quite easily. If the following code
# is saved as 'foo' for instance.
#
#   MyCmd << Console::Command
#
#     help "Dispays the word JUMP!"
#
#     def jump
#       if $VERBOSE
#         puts "JUMP! JUMP! JUMP!"
#       else
#         puts "Jump"
#       end
#     end
#
#   end
#
#   MyCmd.execute
#
# then by running 'foo help' on the command line, standard help information
# will be displayed.
#
#   foo
#
#     jump  Displays the word JUMP!
#
#++

class Console::Command

  # Representation of a single commandline option.

  class Option < String

    def initialize(option)
      @flag = option
      @long = (/^--/ =~ option)
      super(option.sub(/^-{1,2}/,''))
    end

    def long?
      @long
    end

    def short?
      !@long
    end

    #def demethodize
    #  sub('__','--').sub('_','-')
    #end

    def methodize
      @flag.gsub('-','_')
    end

  end

  # Command Syntax DSL
  #
  module Syntax

    # Starts the command execution.
    def execute( *args )
      cmd = new()
      #cmd.instance_variable_set("@global_options",global_options)
      cmd.execute( *args )
    end
    alias_method :start, :execute

    # Change the option mode.
    def global_option( *names )
      names.each{ |name| global_options << name.to_sym }
    end

    # TODO collect ancestors global_options
    def global_options
      @global_options ||= []
    end

    #
    def option(name, &block)
      name = name.to_s
      if name.size > 1
        methname = "__#{name}"
      else
        methname = "_#{name}"
      end
      define_method(methname, &block)
    end

    #
    def subcommand(name, subclass=nil, &block)
      if block_given?
        base = self
        define_method(name) do |*args|
          Class.new(base, &block).new(self).execute(args)
        end
      else
        raise "not a command" unless subclass < Command
        define_method(name) do |*args|
          subclass.new(self).execute(args)
        end
      end
    end

  end

  extend Syntax

  attr :parent

  #def initialize #(global_options=nil)
  #  #@global_options = global_options || []
  #end

  def initialize(parent=nil)
    @parent = parent
     # TODO is iv transfer really a good idea?
    if parent
      parent.instance_variables.each do |iv|
        next if iv == "@parent"
        instance_variable_set(iv, parent.instance_variable_get(iv))
      end
    end
  end

  # Execute the command.

  def execute(line=nil)
    case line
    when String
      arguments = Shellwords.shellwords(line)
    when Array
      arguments = line
    else
      arguments = ARGV
    end

    # duplicate arguments to work on them in-place.

    argv = arguments.dup

    # Split single letter option groupings into separate options.
    # ie. -xyz => -x -y -z

    argv = argv.collect { |arg|
      if md = /^-(\w{2,})/.match( arg )
        md[1].split(//).collect { |c| "-#{c}" }
      else
        arg
      end
    }.flatten

    # process global options
    global_options.each do |name|
      o = name.to_s.sub('__','--').sub('_','-')
      m = method(name)
      c = m.arity
      while i = argv.index(o)
        args = argv.slice!(i,c+1)
        args.shift
        m.call(*args)
      end
    end

    # Does this command take subcommands?
    subcommand = !respond_to?(:main)

    # process primary options
    argv = execute_options( argv, subcommand )

    # If this command doesn't take subcommands, then
    # the remaining arguments are arguments for main().
    return send(:main, *argv) unless subcommand

    # What to do if there is nothing else?
    if argv.empty?
      if respond_to?(:default)
        return __send__(:default)
      else
        $stderr << "Nothing to do."
        return
      end
    end

    # Remaining arguments are subcommand and suboptions.

    subcmd = argv.shift.gsub('-','_')
    #puts "subcmd = #{subcmd}"

    #    # Extend subcommand option module
    #    subconst = subcmd.gsub(/\W/,'_').capitalize
    #    #puts self.class.name
    #    if self.class.const_defined?(subconst)
    #      puts "Extending self (#{self.class}) with subcommand module #{subconst}" if $debug
    #      submod = self.class.const_get(subconst)
    #      self.extend submod
    #    end

    # process subcommand options
    #puts "Treating the rest of the args as subcommand options:"
    #argv = execute_options( argv )

    # This is a little tricky. The method has to be defined by a subclass.
    if self.respond_to?(subcmd) and not Console::Command.public_instance_methods.include?(subcmd.to_s)
      puts "Calling #{subcmd}(#{argv.inspect})" if $debug
      __send__(subcmd, *argv)
    else
      begin
        puts "Calling method_missing with #{subcmd}, #{argv.inspect}" if $debug
        method_missing(subcmd.to_sym, *argv)
      rescue NoMethodError => e
        #if self.private_methods.include?( "no_command_error" )
        #  no_command_error( *args )
        #else
          $stderr << "Unrecognized subcommand -- #{subcmd}\n"
          exit -1
        #end
      end
    end

  #   rescue => err
  #     if $DEBUG
  #       raise err
  #     else
  #       msg = err.message.chomp('.') + '.'
  #       msg[0,1] = msg[0,1].capitalize
  #       msg << " (#{err.class})" if $VERBOSE
  #       $stderr << msg
  #     end
  end

  private

  # Return the list of global options.

  def global_options
    self.class.global_options
  end

  #

  def execute_options( argv, break_on_subcommand=false )
    puts "in execute_options:" if $debug
    argv = argv.dup
    args_to_return = []
    until argv.empty?
      arg = argv.first
      if arg[0,1] == '-'
        puts "'#{arg}' -- is an option" if $debug
        opt  = Option.new(arg)
        name = opt.methodize
        if respond_to?(name)
          m = method(name)
          puts "Method named #{name} exists and has an arity of #{m.arity}" if $debug
          if m.arity == -1
            # Implemented the same as for option_missing, except that we don't pass the *name* of the option
            arity = m.call(*argv[1..-1]) || 1
            puts "#{name} returned an arity of #{arity}" if $debug
            unless arity.is_a?(Fixnum)
              raise "Expected #{name} to return a valid arity, but it didn't"
            end
            #puts "argv before: #{argv.inspect}"
            argv.shift              # Get rid of the *name* of the option
            argv.slice!(0, arity)   # Then discard as many arguments as that option claimed it used up
            #puts "argv after: #{argv.inspect}"
          else
            # The +1 is so that we also remove the option name from argv
            args_for_current_option = argv.slice!(0, m.arity+1)
            # Remove the option name from args_for_current_option as well
            args_for_current_option.shift
            m.call(*args_for_current_option)
          end
        elsif respond_to?(:option_missing)
          puts "  option_missing(#{argv.inspect})" if $debug
          #arity = option_missing(arg.gsub(/^[-]+/,''), argv[1..-1]) || 1
          arity = option_missing(opt, argv[1..-1]) || 1
          unless arity.is_a?(Fixnum)
            raise "Expected #{name} to return a valid arity, but it didn't"
          end
          argv.slice!(0, arity)
          argv.shift  # Get rid of the *name* of the option
        else
  # IMPORTANT!!! WHEN HAND TESTING UNREMARK THE NEXT LINE. HOW TO FIX?
          #raise InvalidOptionError.new(arg)
          $stderr << "Unknown option '#{arg}'.\n"
          exit -1
        end
      else
        puts "'#{arg}' -- not an option. Adding to args_to_return..." if $debug
        if break_on_subcommand
          # If we are parsing options for the *main* command and we are allowing
          # subcommands, then we want to stop as soon as we get to the first non-option,
          # because that non-option will be the name of our subcommand and all options that
          # follow should be parsed later when we handle the subcommand.
          args_to_return = argv
          break
        else
          args_to_return << argv.shift
        end
      end
    end
    puts "Returning #{args_to_return.inspect}" if $debug
    return args_to_return
  end

  public

=begin
 # We include a module here so you can define your own help
 # command and call #super to utilize this one.

 module Help

   def help
     opts = help_options
     s = ""
     s << "#{File.basename($0)}\n\n"
     unless opts.empty?
       s << "OPTIONS\n"
       s << help_options
       s << "\n"
     end
     s << "COMMANDS\n"
     s << help_commands
     puts s
   end

   private

   def help_commands
     help = self.class.help
     bufs = help.keys.collect{ |a| a.to_s.size }.max + 3
     lines = []
     help.each { |cmd, str|
       cmd = cmd.to_s
       if cmd !~ /^_/
         lines << "  " + cmd + (" " * (bufs - cmd.size)) + str
       end
     }
     lines.join("\n")
   end

   def help_options
     help = self.class.help
     bufs = help.keys.collect{ |a| a.to_s.size }.max + 3
     lines = []
     help.each { |cmd, str|
       cmd = cmd.to_s
       if cmd =~ /^_/
         lines << "  " + cmd.gsub(/_/,'-') + (" " * (bufs - cmd.size)) + str
       end
     }
     lines.join("\n")
   end

   module ClassMethods

     def help( str=nil )
       return (@help ||= {}) unless str
       @current_help = str
     end

     def method_added( meth )
       if @current_help
         @help ||= {}
         @help[meth] = @current_help
         @current_help = nil
       end
     end

   end

 end

 include Help
 extend Help::ClassMethods
=end

end

# For Command, but defined external to it, so
# that it is easy to access from user defined commands.
# (This lookup issue should be fixed in Ruby 1.9+, and then
# the class can be moved back into Command namespace.)

class InvalidOptionError < StandardError
  def initialize(option_name)
    @option_name = option_name
  end
  def message
    "Unknown option '#{@option_name}'."
  end
end



#  _____         _
# |_   _|__  ___| |_
#   | |/ _ \/ __| __|
#   | |  __/\__ \ |_
#   |_|\___||___/\__|
#

=begin test

  require 'test/unit'
  require 'stringio'

  include Console

  class TestCommand < Test::Unit::TestCase
    Output = []

    def setup
      Output.clear
      $stderr = StringIO.new
    end

    class TestCommand < Command
    end

    # Test basic command.

    class SimpleCommand < TestCommand
      def __here ; @here = true ; end

      def main(*args)
        Output.concat([@here] | args)
      end
    end

    def test_SimpleCommand
      cmd = SimpleCommand.new
      cmd.execute( '--here file1 file2' )
      assert_equal( [true, 'file1', 'file2'], Output )
    end

    # Test Subcommand.

    class FooSubcommand < TestCommand
      def main
        Output << "here"
      end
    end

    class CommandUsingSubcommand < TestCommand
      subcommand :foo, FooSubcommand
    end

    def test_CommandUsingSubcommand
      cmd = CommandUsingSubcommand.new
      cmd.execute('foo')
      assert_equal(["here"], Output)
    end

    #

    class CommandWithMethodMissingSubcommand < TestCommand
      def __here ; @here = true ; end

      def method_missing(subcommand, *args)
        Output.concat([@here, subcommand] | args)
      end
    end

    def test_CommandWithMethodMissingSubcommand
      cmd = CommandWithMethodMissingSubcommand.new
      cmd.execute( '--here go file1' )
      assert_equal( [true, 'go', 'file1'], Output )
    end

    #

    class CommandWithSimpleSubcommand < TestCommand
      def __here ; @here = true ; end

      # subcommand
      subcommand :go do
        def _p(n)
          @p = n.to_i
        end
        def main ; Output.concat([@here, @p]) ; end
      end
    end

    def test_CommandWithSimpleSubcommand
      cmd = CommandWithSimpleSubcommand.new
      cmd.execute( '--here go -p 1' )
      assert_equal( [true, 1], Output )
    end

    #

    # Global options can be anywhere, right? Even after subcommands? Let's find out.
    class CommandWithGlobalOptionsAfterSubcommand < TestCommand
      def _x ; @x = true ; end
      global_option :_x

      subcommand :go do
        def _p(n)
          @p = n.to_i
        end

        def main ; Output.concat([@x, @p]) ; end
      end
    end

    def test_CommandWithGlobalOptionsAfterSubcommand_01
      cmd = CommandWithGlobalOptionsAfterSubcommand.new
      cmd.execute( 'go -x -p 1' )
      assert_equal( [true, 1], Output )
    end

    def test_CommandWithGlobalOptionsAfterSubcommand_02
      cmd = CommandWithGlobalOptionsAfterSubcommand.new
      cmd.execute( 'go -p 1 -x' )
      assert_equal( [true, 1], Output )
    end

    #

    class GivingUnrecognizedOptions < TestCommand
      def _x ; @x = true ; end
      def go ; Output.concat([@x, @p]) ; end
    end

    def test_GivingUnrecognizedOptions
      cmd = GivingUnrecognizedOptions.new
      assert_raise(SystemExit) do
        cmd.execute( '--an-option-that-wont-be-recognized -x go' )
      end
      assert_equal "Unknown option '--an-option-that-wont-be-recognized'.\n", $stderr.string
      assert_equal( [], Output )
    end

    #

    class PassingMultipleSingleCharOptionsAsOneOption < TestCommand
      def _x ; @x = true ; end
      def _y ; @y = true ; end
      def _z(n) ; @z = n ; end

      global_option :_x

      subcommand :go do
        def _p(n)
          @p = n.to_i
        end
        def main ; Output.concat([@x, @y, @z, @p]) ; end
      end
    end

    def test_PassingMultipleSingleCharOptionsAsOneOption
      cmd = PassingMultipleSingleCharOptionsAsOneOption.new
      cmd.execute( '-xy -z HERE go -p 1' )
      assert_equal( [true, true, 'HERE', 1], Output )
    end

    #

    class CommandWithOptionUsingEquals < TestCommand
      subcommand :go do
        def __mode(mode) ; @mode = mode ; end
        def main ; Output.concat([@mode]) ; end
      end
    end

    def test_CommandWithOptionUsingEquals
      cmd = CommandWithOptionUsingEquals.new
      cmd.execute( 'go --mode smart' )
      assert_equal( ['smart'], Output )

      # I would expect this to work too, but currently it doesn't.
      #assert_nothing_raised { CommandWithOptionUsingEquals.execute( 'go --mode=smart' ) }
      #assert_equal( ['smart'], Output )
    end

    #

    class CommandWithSubcommandThatTakesArgs < TestCommand
      def go(arg1, *args) ; Output.concat([arg1] | args) ; end
    end

    def test_CommandWithSubcommandThatTakesArgs
      cmd = CommandWithSubcommandThatTakesArgs.new
      cmd.execute( 'go file1 file2 file3' )
      assert_equal( ['file1', 'file2', 'file3'], Output )
    end

    #

    class CommandWith2OptionalArgs < TestCommand
      def __here ; @here = true ; end

      subcommand :go do
        def _p(n)
          @p = n.to_i
        end

        def main(required1 = nil, optional2 = nil)
          Output.concat [@here, @p, required1, optional2]
        end
      end
    end

    def test_CommandWith2OptionalArgs
      cmd = CommandWith2OptionalArgs.new
      cmd.execute( '--here go -p 1 to' )
      assert_equal( [true, 1, 'to', nil], Output )
    end

    #

    class CommandWithVariableArgs < TestCommand
      def __here ; @here = true ; end

      subcommand :go do
        def _p(n)
          @p = n.to_i
        end

        def main(*args) ; Output.concat([@here, @p] | args) ; end
      end
    end

    def test_CommandWithVariableArgs
      cmd = CommandWithVariableArgs.new
      cmd.execute( '--here go -p 1 to bed' )
      assert_equal( [true, 1, 'to', 'bed'], Output )
    end

    #

    class CommandWithOptionMissing < TestCommand
      def __here ; @here = true ; end

      subcommand :go do
        def option_missing(option_name, args)
          p args if $debug
          case option_name
          when 'p'
            @p = args[0].to_i
            1
          else
            raise InvalidOptionError(option_name, args)
          end
        end

        def main(*args) ; Output.concat([@here, @p] | args) ; end
      end
    end

    def test_CommandWithOptionMissing
      cmd = CommandWithOptionMissing.new
      cmd.execute( '--here go -p 1 to bed right now' )
      assert_equal( [true, 1, 'to', 'bed', 'right', 'now'], Output )
    end

    #

    class CommandWithOptionMissingArityOf2 < TestCommand
      def __here ; @here = true ; end

      subcommand :go do
        def option_missing(option_name, args)
          p args if $debug
          case option_name
            when 'p'
              @p1 = args[0].to_i
              @p2 = args[1].to_i
              2
            when 'q'
              @q = args[0].to_i
              nil # Test default arity
            else
              raise InvalidOptionError(option_name, args)
          end
        end

        def main(*args) ; Output.concat [@here, @p1, @p2, @q] | args ; end
      end
    end

    def test_CommandWithOptionMissingArityOf2
      cmd = CommandWithOptionMissingArityOf2.new
      cmd.execute( '--here go -p 1 2 -q 3 to bed right now' )
      assert_equal( [true, 1, 2, 3, 'to', 'bed', 'right', 'now'], Output )
    end

  end

=end


# Author::    Thomas Sawyer, Tyler Rick
# Copyright:: Copyright (c) 2005-2007
# License::   Ruby License
