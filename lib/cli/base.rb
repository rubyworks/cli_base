module CLI

  # = CLI::Base
  #
  #   class MyCLI < CLI::Base
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
  #     class Remote < CLI::Base
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
  #       def force=(bool)
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
  class Base

    require 'cli/errors'
    require 'cli/parser'
    require 'cli/help'

    #
    def main(*args)
      #puts self.class  # TODO: fix help
      raise NoCommandError
    end

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
        cli, args = parser.parse(argv)
        cli.main(*args)
        return cli
      end

      # CLI::Base classes don't run, they execute! But...
      alias_method :run, :execute

      #
      def parser
        @parser ||= Parser.new(self)
      end

      # List of subcommands.
      def subcommands
        parser.subcommands
      end

      # Interface with cooresponding help object.
      def help
        @help ||= Help.new(self)
      end

      # Get or set a help banner for the command.
      def banner(text=nil)
        help.banner(text)
      end
      alias_method :header, :banner

      # Get or set a help footer for the command.
      def footer(text=nil)
        help.footer(text)
      end

      # Hash for storing descriptions.   
      #def descriptions
      #  @descriptions ||= (
      #    parent = ancestors[1]
      #    if CLI::Base > parent
      #      parent.descriptions.dup
      #    else
      #      {}
      #    end
      #  )
      #end

      #
      #def method_added(name)
      #  #name = name.to_s.chomp('?').chomp('=')
      #  descriptions[name.to_s] = @help if @help
      #  @help = nil
      #end

      #
      def inspect
        name
      end

      #
      def to_s
        help.help_text
      end

    end

  end

end
