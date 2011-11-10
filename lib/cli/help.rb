module CLI

  require 'cli/core_ext'

  # Encpsulates command help for deefining and displaying well formated help
  # output in plain text or via manpages if found.
  class Help

    # Setup new help object.
    def initialize(cli_class)
      @cli_class = cli_class

      @banner  = nil
      @footer  = nil

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

    # Get or set command banner.
    def banner(text=nil)
      @banner ||= cli_class.config.header
      @banner ||= File.basename($0) + ' [options...] [subcommand]'
      @banner = text unless text.nil?
      @banner
    end

    # Set command banner.
    def banner=(text)
      @banner = text
    end

    # Get or set command description.
    def description(text=nil)
      @description = text unless text.nil?
    end
    alias_method :header, :description

    # Get or set command help footer.
    def footer(text=nil)
      @footer ||= cli_class.config.footer
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
      s << text_banner
      s << text_description
      s << text_subcommands
      s << text_options
      s << text_footer
      s.compact.join("\n\n")
    end

    # Command usage banner.
    def text_banner
      banner
    end

    # TODO: Maybe default description should always come from `main`
    # instead of the the class comment. 

    # Description of command in printable form.
    # But will return +nil+ if there is no description.
    #
    # @return [String,NilClass] command description
    def text_description
      if @description
        @description
      elsif @file
        get_above_comment(@file, @line).join("\n")
      elsif desc = method_descriptions['main']
        desc
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
      descriptions = option_descriptions

      options  = {}

      descriptions.each do |meth, desc|
        case meth
        when /^(.*?)[\!\=]$/
          options[$1] = descriptions[meth]
        end
      end

      options.update(@options)

      options = options.sort{ |a,b| a[0] <=> b[0] }

      s = []
      s << "OPTIONS"
      options.each do |(name, desc)|
        if name.size == 1
          s << "   -%-15s %s" % [name, desc]
        else
          s << "  --%-15s %s" % [name, desc]
        end
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
    def option_descriptions
      @option_descriptions ||= method_descriptions
    end

  private

    #
    def method_descriptions
      h = {}
      c = method_chart(@cli_class)
      c.each do |o,d|
        h[o.to_s] = d.first if d
      end
      h
    end

    # Produce an index of method to method description.
    #
    def method_chart(cli_class)
      chart = {}

      methods   = []
      stop_at   = cli_class.ancestors.index(CLI::Base) || -1
      ancestors = cli_class.ancestors[0...stop_at]
      ancestors.reverse_each do |a|
        methods.concat(a.instance_methods(false))
      end

      methods.each do |m|
        file, line = cli_class.instance_method(m).source_location
        chart[m] = get_above_comment(file, line)
      end

      chart
    end

    # Get comment from file searching up from given line number.
    #
    def get_above_comment(file, line)
      text  = read(file)
      index = line - 1
      while index >= 0 && text[index] !~ /^\s*\#/
        return nil if text[index] =~ /^\s*end/
        index -= 1
      end
      rindex = index
      while text[index] =~ /^\s*\#/
        index -= 1
      end
      result = text[index..rindex]
      result = result.map{ |s| s.strip }
      result = result.reject{ |s| s[0,1] != '#' }
      result = result.map{ |s| s.sub(/^#/,'').strip }
      result = result.reject{ |s| s == "" }
      result
    end

    # Get comment from file searching down from given line number.
    #
    # @param file [String] filename, should be full path
    # @param line [Integer] line number in file
    #
    def get_following_comment(file, line)
      text  = read(file)
      index = line || 0
      while text[index] !~ /^\s*\#/
        return nil if text[index] =~ /^\s*(class|module)/
        index += 1
      end
      rindex = index
      while text[rindex] =~ /^\s*\#/
        rindex += 1
      end
      result = text[index..(rindex-2)]
      result = result.map{ |s| s.strip }
      result = result.reject{ |s| s[0,1] != '#' }
      result = result.map{ |s| s.sub(/^#/,'').strip }
      result.join("\n").strip
    end

    # Read and cache file.
    #
    # @param file [String] filename, should be full path
    #
    # @return [Array] file content in array of lines
    def read(file)
      @read ||= {}
      @read[file] ||= File.readlines(file)
    end

  end

end
