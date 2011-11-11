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
#     class Remote < self
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
#       class Add < subcommand
#
#         def main(name, branch)
#           # ...
#         end
#
#       end
#
#       # $ foo remote show
#
#       class Show < Subcommand()
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

  require 'executioner/help'


  #
  def initialize(master=nil)
    @master = master
  end

  def main(*args)
    #raise MissingCommandError
    raise NoCommandError
  end

  ## Used to invoke the command.
  #def run(argv=ARGV)
  #  args = parse(argv)
  #p args
  #  main(*args)
  #end

  # This is the fallback subcommand. Override this to provide
  # a fallback when no command is given on the commandline.
  #def command_missing
  #  begin
  #    main
  #  rescue NameError
  #    raise MissingCommandError
  #  end
  #end

  # Override option_missing if needed. This receives
  # the name of the option and the remaining arguments
  # list. It must consume any argument it uses from
  # the (begining of) the list.
  def option_missing(opt, argv)
    raise NoOptionError, opt
  end

  class << self

    #
    def execute(argv=ARGV)
      if String === argv
        require 'shellwords'
        argv = Shellwords.shellwords(argv)
      end

      cmd, argv = parse_subcommand(argv)
      cli = cmd.new
      args = parse(cli, argv)

      cli.main(*args)

      return cli
    end

    #
    alias_method :run, :execute

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
    def attr_switch(name)
      attr_writer :name
      module_eval %{
        def #{name}?
          @#{name}
        end
      }
    end

    #
    #def new(argv=ARGV)
    #  if String === argv
    #    require 'shellwords'
    #    argv = Shellwords.shellwords(argv)
    #  end
    #
    #  subc, args = parse(_new, argv)
    #  subc.arguments = args
    #end

    def subcommands
      @subcommands ||= (
        constants.inject({}){ |h, c|
          if Executioner === c      
            n = c.name.split('::').last.downcase
            h[n] = c
          end
          h
        end
      }
    end

    #def inherited(subclass)
    #  name = subclass.name.split('::').last.downcase
    #  subcommands[name] = subclass
    #  #define_method(name.downcase) do
    #  #  subclass.new(self)
    #  #end
    #end

    #  subc, args = parse(obj, argv)
    #  obj.main(*args) unless subc
      #subcmd = args.shift
      #if subcmd && !obj.respond_to?("#{subcmd}=")
      #  begin
      #    obj.send(subcmd, *args)
      #  rescue NoMethodError
      #    raise NoCommandError, subcmd
      #  end
      #else
      #  obj.command_missing
      #end
    #end

    #def run(obj)
    #  methname, args = *parse(obj)
    #  meth = obj.method(methname)
    #  meth.call(*args)
    #end


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
      
      #while argv.size > 0
      #  case opt = argv.shift
      #  when /=/
      #    parse_equal(obj, opt, argv, args)
      #  when /^--/
      #    parse_option(obj, opt, argv, args)
      #  when /^-/
      #    parse_flags(obj, opt, argv, args)
      #  else
      #    args << opt
      #  end
      #end
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
        obj.send("#{x}=", v)
      #elsif obj.respond_to?("#{args.join('_')}_#{x}=")
      #  obj.send("#{args.join('_')}_#{x}=", v)
      else
        obj.option_missing(x, v) # argv?
      end
      #if obj.respond_to?("#{x}=")
      #  # TODO: to_b if 'true' or 'false' ?
      #  obj.send("#{x}=",v)
      #else
      #  obj.option_missing(x, v) # argv?
      #end
    end

    # Parse a command-line option.
    def parse_option(obj, opt, argv, args)
      x = opt.sub(/^\-+/, '') # remove '--'
      #if obj.respond_to?("#{args.join('_')}_#{x}=")
      #  m = obj.method("#{args.join('_')}_#{x}=")
      #  if obj.respond_to?("#{args.join('_')}_#{x}?")
      #    m.call(true)
      #  else
      #    m.call(argv.shift)
      #  end
      #elsif obj.respond_to?("#{args.join('_')}_#{x}?")
      #  m = obj.method("#{args.join('_')}_#{x}?")
      #  a = []
      #  m.arity.abs.times{ a << argv.shift }
      #  m.call(*a)
      #  m.call
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

    # TODO: this needs some thought concerning character spliting and arguments.
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

    #
    def help(description)
      @desc = description
    end

    # Hash for storing descriptions.   
    def descriptions
      @descriptions ||= {}
    end

    #
    def method_added(name)
      #name = name.to_s.chomp('?').chomp('=')
      descriptions[name.to_s] = @desc if @desc
      @desc = nil
    end

    #
    def to_s
      Help.new(self).to_s
    end

  end

  class NoOptionError < ::NoMethodError # ArgumentError ?
    def initialize(name, *arg)
      super("unknown option -- #{name}", name, *args)
    end
  end

  #class NoCommandError < ::NoMethodError
  #  def initialize(name, *args)
  #    super("unknown command -- #{name}", name, *args)
  #  end
  #  alias_method :to_str, :to_s
  #end

  class NoCommandError < ::ArgumentError
    def initialize(*args)
      super("nothing to do", *args)
    end
  end

end
