module CLI

  class Base

    # Encpsulates help output with code to display well formated help
    # output and manpages output.
    class Help

      attr :cli_class

      #
      def initialize(cli_class)
        @cli_class = cli_class
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
        commands     = @cli_class.subcommands
        descriptions = @cli_class.descriptions

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

        s << "\n\n" + @cli_class.header

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
        s << @cli_class.footer if @cli_class.footer
        s << "\n"
        s
      end

    end

  end

end
