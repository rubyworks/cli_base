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
    require 'cli/config'

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
      # This is equivalent to:
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

      # Run the command.
      #
      # @param argv [Array] command-line arguments
      #
      def execute(argv=ARGV)
        cli, args = parser.parse(argv)
        cli.main(*args)
        return cli
      end

      # CLI::Base classes don't run, they execute! But...
      alias_method :run, :execute

      # Command configuration options.
      #
      # @todo: This isn't used yet. Eventually the idea is to allow
      #   some additional flexibility in the parser behavior.
      def config
        @config ||= Config.new
      end

      # The parser for this command.
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

      #
      def inspect
        name
      end

      # When inherited, setup up the +file+ and +line+ of the 
      # subcommand via +caller+. If for some odd reason this
      # does not work then manually use +setup+ method.
      #
      def inherited(subclass)
        file, line, _ = *caller.first.split(':')
        file = File.expand_path(file)
        subclass.help.setup(file,line.to_i)
      end

    end

    # Access the help instance of the class of the command object.
    def cli_help
      self.class.help
    end

  end

end
