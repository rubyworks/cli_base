module CLI

  # Encpsulates help output with code to display well formated help
  # output and manpages output.
  class Help

    #
    attr :cli_class

    #
    def banner(text=nil)
      @banner = text unless text.nil?
      @banner
    end

    def banner=(text)
      @banner = text
    end

    #
    def footer(text=nil)
      @footer = text unless text.nil?
      @footer
    end

    def footer=(text)
      @footer = text
    end

    #
    def initialize(cli_class)
      @cli_class = cli_class
    end

    #alias_method :inspect, :to_s

    #
    #def to_s
    #  help_text
    #end

    # TODO: how to find manpage file?
    def to_manpage
    end

    #
    def help_text
      commands     = @cli_class.subcommands
      descriptions = option_descriptions

      options  = []

      descriptions.each do |meth, desc|
        case meth
        when /^(.*?)[\!\=]$/
          options << [$1, meth]
        end
      end

      options = options.sort{ |a,b| a[0] <=> b[0] }

      s = ''
      s << File.basename($0)

      s << "\n\n" + banner.to_s if banner

      if !commands.empty?
        s << "\n\nCOMMANDS:\n\n"
        commands.each do |cmd, klass|
          s << "  %-15s %s\n" % [cmd, klass.description]
        end
      end

      s << "\n\nOPTIONS:\n\n"
      options.each do |(name, meth)|
        if name.size == 1
          s << "   -%-15s %s\n" % [name, descriptions[meth]]
        else
          s << "  --%-15s %s\n" % [name, descriptions[meth]]
        end
      end

      #s << "\nCOMMON OPTIONS:\n\n"
      #global_options.each do |(name, meth)|
      #  if name.size == 1
      #    s << "   -%-15s %s\n" % [name, descriptions[meth]]
      #  else
      #    s << "  --%-15s %s\n" % [name, descriptions[meth]]
      #  end
      #end

      s << "\n"
      s << footer if footer
      s << "\n"
      s
    end

    #
    def option_descriptions
      h = {}
      chart(@cli_class).each do |o,d|
        h[o.to_s] = d.first
      end
      h
    end

    # TODO: deal with depth
    def chart(cli_class)
      chart = {}

      methods   = []
      stop_at   = cli_class.ancestors.index(CLI::Base) || -1
      ancestors = cli_class.ancestors[0...stop_at]
      ancestors.reverse_each do |a|
        methods.concat(a.instance_methods(false))
      end

      methods.each do |m|
        file, line = cli_class.instance_method(m).source_location
        chart[m] = get_comment(file, line)
      end

      chart
    end

    #
    def get_comment(file,line)
      text  = read(file)
      index = line - 2
      while text[index] =~ /^\s*\#/
        index = index - 1
      end
      result = text[index..(line-2)]
      result = result.map{ |s| s.strip }
      result = result.reject{ |s| s[0,1] != '#' }
      result = result.map{ |s| s.sub(/^#/,'').strip }
      result = result.reject{ |s| s == "" }
      result
    end

    #
    def read(file)
      @file ||= {}
      @file[file] ||= File.readlines(file)
    end

  end

end
