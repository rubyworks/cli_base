class Executioner

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
