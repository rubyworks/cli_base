module CLI

  require 'cli/source'
  require 'cli/core_ext'

  # Encpsulates command help for deefining and displaying well formated help
  # output in plain text or via manpages if found.
  class Help

    # Setup new help object.
    def initialize(cli_class)
      @cli_class = cli_class

      @usage  = nil
      @footer = nil

      @options = {}
      @subcmds = {}
    end

    # Set file and line under which the CLI::Base subclass is defined.
    def setup(file, line=nil)
      @file = file
      @line = line
    end

    # The CLI::Base subclass to which this help applies.
    attr :cli_class

    # Get or set command name.
    # 
    # By default the name is assumed to be the class name, substituting
    # dashes for double colons.
    def name(name=nil)
      @name = name if name
      @name ||= cli_class.name.downcase.gsub('::','-')
                #File.basename($0)
      @name
    end

    # Get or set command usage.
    def usage(text=nil)
      @usage ||= "Usage: " + File.basename($0) + ' [options...] [subcommand]'
      @usage = text unless text.nil?
      @usage
    end

    # Set command usage.
    def usage=(text)
      @usage = text
    end

    # Get or set command description.
    def description(text=nil)
      @description = text unless text.nil?
    end
    alias_method :header, :description

    # Get or set command help footer.
    def footer(text=nil)
      @footer = text unless text.nil?
      @footer
    end

    # Set comamnd help footer.
    def footer=(text)
      @footer = text
    end

    # Set description of an option.
    def option(name, description)
      @options[name.to_s] = description
    end

    # Set desciption of a subcommand.
    def subcommand(name, description)
      @subcmds[name.to_s] = description
    end

    #alias_method :inspect, :to_s

    # Show help.
    #
    # @todo man-pages will probably fail on Windows
    def show_help(hint=nil)
      if file = manpage(hint)
        system "man #{file}"
      else
        puts text
      end
    end

    # M A N P A G E

    # Get man-page if there is one.
    def manpage(hint=nil)
      @manpage ||= (
        man  = []
        dir  = @file ? File.dirname(@file) : nil
        glob = "man/#{name}.1"

        if hint
          if File.exist?(hint)
            return hint
          elsif File.directory?(hint)
            dir = hint
          else
            glob = hint if hint
          end
        end

        if dir
          while dir != '/'
            man.concat(Dir[File.join(dir, glob)])
            #man.concat(Dir[File.join(dir, "man/man1/#{name}.1")])
            #man.concat(Dir[File.join(dir, "man/#{name}.1.ronn")])
            #man.concat(Dir[File.join(dir, "man/man1/#{name}.1")])
            break unless man.empty?
            dir = File.dirname(dir)
          end
        end

        man.first
      )
    end

    # H E L P  T E X T

    #
    def to_s; text; end

    #
    def text(file=nil)
      s = []
      s << text_usage
      s << text_description
      s << text_subcommands
      s << text_options
      s << text_footer
      s.compact.join("\n\n")
    end

    # Command usage.
    def text_usage
      usage
    end

    # TODO: Maybe default description should always come from `main`
    # instead of the the class comment ?

    # Description of command in printable form.
    # But will return +nil+ if there is no description.
    #
    # @return [String,NilClass] command description
    def text_description
      if @description
        @description
      elsif @file
        Source.get_above_comment(@file, @line)
      elsif main = method_list.find{ |m| m.name == 'main' }
        main.comment
      else
        nil
      end
    end

    # List of subcommands converted to a printable string.
    # But will return +nil+ if there are no subcommands.
    #
    # @return [String,NilClass] subcommand list text
    def text_subcommands
      commands = @cli_class.subcommands
      s = []
      if !commands.empty?
        s << "COMMANDS"
        commands.each do |cmd, klass|
          desc = klass.help.text_description.to_s.split("\n").first
          s << "  %-17s %s" % [cmd, desc]
        end
      end
      return nil if s.empty?
      return s.join("\n")
    end

    # List of options coverted to a printable string.
    # But will return +nil+ if there are no options.
    # 
    # @return [String,NilClass] option list text
    def text_options
      option_list.each do |opt|
        if @options.key?(opt.name)
          opt.description = @options[opt.name]
        end
      end    

      max = option_list.map{ |opt| opt.usage.size }.max + 2

      s = []
      s << "OPTIONS"
      option_list.each do |opt|
        mark = (opt.name.size == 1 ? ' -' : '--')
        s << "  #{mark}%-#{max}s %s" % [opt.usage, opt.description]
      end
      s.join("\n")
    end

    #
    def text_footer
      footer
    end

    #
    #def text_common_options
      #s << "\nCOMMON OPTIONS:\n\n"
      #global_options.each do |(name, meth)|
      #  if name.size == 1
      #    s << "   -%-15s %s\n" % [name, descriptions[meth]]
      #  else
      #    s << "  --%-15s %s\n" % [name, descriptions[meth]]
      #  end
      #end
    #end

    #
    def option_list
      @option_list ||= (
        method_list.map do |meth|
          case meth.name
          when /^(.*?)[\!\=]$/
            Option.new(meth)
          end
        end.compact.sort
      )
    end

  private

    # Produce a list relavent methods.
    #
    def method_list
      list      = []
      methods   = []
      stop_at   = cli_class.ancestors.index(CLI::Base) || -1
      ancestors = cli_class.ancestors[0...stop_at]
      ancestors.reverse_each do |a|
        a.instance_methods(false).each do |m|
          list << cli_class.instance_method(m)
        end
      end
      list
    end

    # Encapsualtes a command line option.
    class Option
      def initialize(method)
        @method = method
      end

      def name
        @method.name.to_s.chomp('!').chomp('=')
      end

      def comment
        @method.comment
      end

      def description
        @description ||= comment.split("\n").first
      end

      # Set description manually.
      def description=(desc)
        @description = desc
      end

      def parameter
        param = @method.parameters.first
        param.last if param
      end

      def usage
        if parameter
          "#{name}=#{parameter.to_s.upcase}"
        else
          "#{name}"
        end
      end

      def <=>(other)
        self.name <=> other.name
      end
    end
  end

end
