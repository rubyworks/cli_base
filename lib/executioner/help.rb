class Executioner

  # Encpsulates help output with code to display well formated help
  # output and manpages output.
  class Help

    attr :exe_class

    #
    def initialize(exe_class)
      @exe_class = exe_class
    end

    #alias_method :inspect, :to_s

    #
    #def to_s
    #  help_text
    #end

    #
    def to_manpage
    end

    #
    def help_text
      commands = @exe_class.subcommands

      options  = []

      descriptions = @exe_class.descriptions

      #descs = descriptions.to_a.sort{ |a,b| a[0] <=> b[0] }

      descriptions.each do |meth, desc|
        case meth
        when /^(.*?)[\!\=]$/
          options << [$1, meth]
        end
      end

      s = ''
      s << File.basename($0)

      s << "\n\n" + @exe_class.description

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
      s
    end

  end

end
