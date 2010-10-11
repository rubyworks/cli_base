# = Executioner
#
#   class MyCLI < Executioner
#
#     # cmd --debug
#
#     def debug?
#       $DEBUG
#     end
#
#     def debug=(bool)
#       $DEBUG = bool
#     end
#
#     # $ foo remote
#
#     class Remote < Executioner
#
#       # $ foo remote --verbose
#
#       def verbose?
#         @verbose
#       end
#
#       def verbose=(bool)
#         @verbose = bool
#       end
#
#       # $ foo remote --force
#
#       def force?
#         @force
#       end
#
#       def remote=(bool)
#         @force = bool
#       end
#
#       # $ foo remote --output <path>
#
#       def output=(path)
#         @path = path
#       end
#
#       # $ foo remote -o <path>
#
#       alias_method :o=, :output=
#
#       # $ foo remote add
#
#       class Add < self
#
#         def main(name, branch)
#           # ...
#         end
#
#       end
#
#       # $ foo remote show
#
#       class Show < self
#
#         def main(name)
#           # ...
#         end
#
#       end
#
#     end
#
#   end
#
class Executioner

  require 'executioner/errors'
  require 'executioner/help'

  #
  def main(*args)
    #puts self.class  # TODO: fix help
    raise NoCommandError
  end

  private

  # Override option_missing if needed. This receives
  # the name of the option and the remaining arguments
  # list. It must consume any argument it uses from
  # the (begining of) the list.
  def option_missing(opt, argv)
    raise NoOptionError, opt
  end

  class << self

    # Helper method for creating switch attributes.
    #
    #   def name=(val)
    #     @name = val
    #   end
    #
    #   def name?
    #     @name
    #   end
    #
    def attr_switch(name)
      attr_writer name
      module_eval %{
        def #{name}?
          @#{name}
        end
      }
    end

    #
    def execute(argv=ARGV)
      argv = parse_arguments(argv)

      cmd, argv = parse_subcommand(argv)
      cli  = cmd.new
      args = parse(cli, argv)

      cli.main(*args)

      return cli
    end

    # Executioners don't run, they execute! But...
    alias_method :run, :execute

    # List if subcommands.
    def subcommands
      @subcommands ||= (
        consts = constants - superclass.constants
        consts.inject({}) do |h, c|
          c = const_get(c)
          if Executioner > c
            n = c.name.split('::').last.downcase
            h[n] = c
          end
          h
        end
      )
    end

    # Make sure arguments are an array. If argv is a String,
    # then parse using Shellwords module.
    def parse_arguments(argv)
      if String === argv
        require 'shellwords'
        argv = Shellwords.shellwords(argv)
      end
      argv.to_a
    end

    #
    def parse_subcommand(argv)
      cmd = self
      arg = argv.first

      while c = cmd.subcommands[arg]
        cmd = c
        argv.shift
        arg = argv.first
      end

      return cmd, argv
    end

    #
    def parse(obj, argv, args=[])
      case argv
      when String
        require 'shellwords'
        argv = Shellwords.shellwords(argv)
      #else
      #  argv = argv.dup
      end

      #subc = nil
      #@args = []  #opts, i = {}, 0

      while argv.size > 0
        case arg = argv.shift
        when /=/
          parse_equal(obj, arg, argv, args)
        when /^--/
          parse_option(obj, arg, argv, args)
        when /^-/
          parse_flags(obj, arg, argv, args)
        else
          #if Executioner === obj
          #  if cmd_class = obj.class.subcommands[arg]
          #    cmd  = cmd_class.new(obj)
          #    subc = cmd
          #    parse(cmd, argv, args)
          #  else
              args << arg
          #  end
          #end
        end
      end
     
      return args
    end

    #
    def parse_equal(obj, opt, argv, args)
      if md = /^[-]*(.*?)=(.*?)$/.match(opt)
        x, v = md[1], md[2]
      else
        raise ArgumentError, "#{x}"
      end
      if obj.respond_to?("#{x}=")
        obj.send("#{x}=", v)  # TODO: to_b if 'true' or 'false' ?
      else
        obj.option_missing(x, v) # argv?
      end
    end

    # Parse a command-line option.
    def parse_option(obj, opt, argv, args)
      x = opt.sub(/^\-+/, '') # remove '--'
      if obj.respond_to?("#{x}=")
        m = obj.method("#{x}=")
        if obj.respond_to?("#{x}?")
          m.call(true)
        else
          invoke(obj, m, argv)
        end
      elsif obj.respond_to?("#{x}!")
        invoke(obj, "#{x}!", argv)
      else
        obj.option_missing(x, argv)
      end
    end

    # TODO: This needs some thought concerning character spliting and arguments.
    def parse_flags(obj, opt, argv, args)
      x = opt[1..-1]
      c = 0
      x.split(//).each do |k|
        if obj.respond_to?("#{k}=")
          m = obj.method("#{k}=")
          if obj.respond_to?("#{x}?")
            m.call(true)
          else
            invoke(obj, m, argv) #m.call(argv.shift)
          end
        elsif obj.respond_to?("#{k}!")
          invoke(obj, "#{k}!", argv)
        else
          long = find_longer_option(obj, k)
          if long
            if long.end_with?('=') && obj.respond_to?(long.chomp('=')+'?')
              invoke(obj, long, [true])
            else
              invoke(obj, long, argv)
            end
          else
            obj.option_missing(x, argv)
          end
        end
      end
    end

    #
    def invoke(obj, meth, argv)
      m = Method === meth ? meth : obj.method(meth)
      a = []
      m.arity.abs.times{ a << argv.shift }
      m.call(*a)
    end

    # TODO: Sort alphabetically?
    def find_longer_option(obj, char)
      meths = obj.methods.map{ |m| m.to_s }
      meths = meths.select do |m|
        m.start_with?(k) and (m.end_with?('=') or m.end_with?('!'))
      end
      meths.first
    end

    # Get or set a help header for the command.
    def header(text=nil)
      @header = text unless text.nil?
      @header
    end

    # Get or set a help footer for the command.
    def footer(text=nil)
      @footer = text unless text.nil?
      @footer
    end

    # Define help information for an option.
    #
    #   help "this options does blah blah"
    #   def foo=(val)
    #     ...
    #   end
    #
    #--
    # TODO: Consider using annotated comments for this information.
    #++
    def help(description)
      @help = description
    end

    # Hash for storing descriptions.   
    def descriptions
      @descriptions ||= (
        parent = ancestors[1]
        if Executioner > parent
          parent.descriptions.dup
        else
          {}
        end
      )
    end

    #
    def method_added(name)
      #name = name.to_s.chomp('?').chomp('=')
      descriptions[name.to_s] = @help if @help
      @help = nil
    end

    #
    def inspect
      name
    end

    #
    def to_s
      Help.new(self).help_text
    end

  end

end
