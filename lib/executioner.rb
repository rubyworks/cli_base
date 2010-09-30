# = Executioner
#
#   class MyCLI < Executioner
#
#     # cmd --debug
#     def debug!(bool)
#       $DEBUG = bool
#     end
#
#     # $ foo remote
#     def remote
#       # ...
#     end
#
#     # $ foo remote --verbose
#     def remote_verbose?
#       @verbose = bool
#     end
#     def remote_verbose=(bool)
#       @verbose = bool
#     end
#
#     # $ foo remote --force
#     def remote_force?
#       @force
#     end
#     def remote_force=(bool)
#       @force = bool
#     end
#
#     # $ foo remote --output <path>
#     def remote_output=(path)
#       @path = path
#     end
#
#     # $ foo remote -o <path>
#     alias_method :remote_o=, :remote_output=
#
#     # $ foo remote add
#     def remote_add(name, branch)
#       # ...
#     end
#
#     # $ foo remote show
#     def remote_show(name)
#       # ...
#     end
#
#   end
#
class Executioner

  class NoOptionError < ::NoMethodError # ArgumentError ?
    def initialize(name, *arg)
      super("unknown option -- #{name}", name, *args)
    end
  end

  class NoCommandError < ::NoMethodError
    def initialize(name, *args)
      super("unknown command -- #{name}", name, *args)
    end
  end

  class MissingCommandError < ::ArgumentError
    def initialize(*args)
      super("missing command", *args)
    end
  end

  # Used to invoke the command.
  def execute_command(argv=ARGV)
    self.class.run(self, argv)
  end
  alias_method :run, :execute_command

  # This is the fallback subcommand. Override this to provide
  # a fallback when no command is given on the commandline.
  def command_missing
    begin
      main
    rescue NameError
      raise MissingCommandError
    end
  end

  # Override option_missing if needed. This receives
  # the name of the option and the remaining arguments
  # list. It must consume any argument it uses from
  # the (begining of) the list.
  def option_missing(opt, *argv)
    raise NoOptionError, opt
  end

  #
  def to_s
    self.class.to_s
  end

  class << self

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
    def run(obj, argv=ARGV)
      args = parse(obj, argv)
      subcmd = args.shift
      if subcmd && !obj.respond_to?("#{subcmd}=")
        begin
          obj.send(subcmd, *args)
        rescue NoMethodError
          raise NoCommandError, subcmd
        end
      else
        obj.command_missing
      end
    end

    #def run(obj)
    #  methname, args = *parse(obj)
    #  meth = obj.method(methname)
    #  meth.call(*args)
    #end

    #
    def parse(obj, argv)
      case argv
      when String
        require 'shellwords'
        argv = Shellwords.shellwords(argv)
      else
        argv = argv.dup
      end

      argv = argv.dup
      args, opts, i = [], {}, 0
      while argv.size > 0
        case opt = argv.shift
        when /=/
          parse_equal(obj, opt, argv, args)
        when /^--/
          parse_option(obj, opt, argv, args)
        when /^-/
          parse_flags(obj, opt, argv, args)
        else
          args << opt
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
        obj.send("#{x}=", v)
      elsif obj.respond_to?("#{args.join('_')}_#{x}=")
        obj.send("#{args.join('_')}_#{x}=", v)
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
      if obj.respond_to?("#{args.join('_')}_#{x}=")
        m = obj.method("#{args.join('_')}_#{x}=")
        if obj.respond_to?("#{args.join('_')}_#{x}?")
          m.call(true)
        else
          m.call(argv.shift)
        end
      #elsif obj.respond_to?("#{args.join('_')}_#{x}!")
      #  m = obj.method("#{args.join('_')}_#{x}!")
      #  a = []
      #  m.arity.abs.times{ a << argv.shift }
      #  m.call(*a)
      elsif obj.respond_to?("#{x}=")
        m = obj.method("#{x}=")
        if obj.respond_to?("#{x}?")
          m.call(true)
        else
          m.call(argv.shift)
        end
      #elsif obj.respond_to?("#{x}!")
      #  m = obj.method("#{x}!")
      #  a = []
      #  m.arity.abs.times{ a << argv.shift }
      #  m.call(*a)
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
            #a = []
            #m.arity.times{ a << argv.shift }
            #m.call(*a)
            m.call(argv.shift)
          end
        #elsif obj.respond_to?("#{k}!")
        #  m = obj.method("#{k}!")
        #  a = []
        #  m.arity.times{ a << argv.shift }
        #  m.call(*a)
        else
          obj.option_missing(x, argv)
        end
        #if obj.respond_to?("#{k}=")
        #  obj.send("#{k}=",true)
        #else
        #  obj.option_missing(x, argv)
        #end
      end
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

    # Encpsulates help output with code to display well formated help
    # output and manpages output.
    class Help

      attr :exe_class

      #
      def initialize(exe_class)
        @exe_class = exe_class
      end

      #
      def to_s
        help_text
      end

      #
      def to_manpage
      end

      #
      def help_text
        commands        = []
        command_options = Hash.new{|h,k| h[k]=[]}
        global_options  = []

        descriptions = exe_class.descriptions

        descs = descriptions.to_a.sort{ |a,b| a[0] <=> b[0] }
        descs.each do |(meth, desc)|
          case meth
          when /_(.*?)[\!\=]$/
            command_options[$`] << [$1, meth]
          when /^(.*?)[\!\=]$/
            global_options << [$1, meth]
          else
            commands << meth
          end
        end

        s = ''
        s << File.basename($0)

        if !commands.empty?
          s << "\n\nCOMMANDS:\n\n"
          commands.each do |cmd|
            s << "  %-15s %s\n" % [cmd, descriptions[cmd]]
          end
        end

        command_options.each do |cmd, opts|
          s << "\nOPTIONS FOR #{cmd}:\n\n"
          opts.each do |(name, meth)|
            if name.size == 1
              s << "   -%-15s %s\n" % [name, descriptions[meth]]
            else
              s << "  --%-15s %s\n" % [name, descriptions[meth]]
            end
          end
        end

        s << "\nCOMMON OPTIONS:\n\n"
        global_options.each do |(name, meth)|
          if name.size == 1
            s << "   -%-15s %s\n" % [name, descriptions[meth]]
          else
            s << "  --%-15s %s\n" % [name, descriptions[meth]]
          end
        end
        s << "\n"
        s
      end

    end

  end

end
