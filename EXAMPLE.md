# Example from OptionParser

Here is an example Executioner subclass that mimics the example
provided in documentation for Ruby built-in OptionParser
(see {here}[http://ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html]).

```ruby
    require 'executioner'
    require 'ostruct'

    # Example of CLI::base
    class ExampleCLI < CLI::Base

      CODES = %w[iso-2022-jp shift_jis euc-jp utf8 binary]
      CODE_ALIASES = { "jis" => "iso-2022-jp", "sjis" => "shift_jis" }

      attr :options

      def initialize
        super
        reset
      end

      def reset
        @options = OpenStruct.new
        @options.library = []
        @options.inplace = false
        @options.encoding = "utf8"
        @options.transfer_type = :auto
        @options.verbose = false
      end

      help "Require the LIBRARY before executing your script"

      def require=(lib)
        options.library << lib
      end
      alias :r= :require=

      # Edit ARGV files in place (make backup if EXTENSION supplied)
      def inplace=(ext)
        options.inplace = true
        options.extension = ext
        options.extension.sub!(/\A\.?(?=.)/, ".")  # ensure extension begins with dot.
      end
      alias :i= :inplace=

      # Delay N seconds before executing.
      # Casts 'delay' argument to a Float.
      def delay=(n)
        options.delay = n.to_float
      end

      # Begin execution at given time.
      # Casts 'time' argument to a Time object.
      def time=(time)
        options.time = Time.parse(time)
      end
      alias :t= :time=

      # Specify record separator (default \\0)
      # Casts to octal integer.
      def irs=(octal)
        options.record_separator = octal.to_i(8)
      end
      alias :F= :irs=

      # Example 'list' of arguments.
      # List of arguments.
      def list=(args)
        options.list = list.split(',')
      end

      # Keyword completion.  We are specifying a specific set of arguments (CODES
      # and CODE_ALIASES - notice the latter is a Hash), and the user may provide
      # the shortest unambiguous text.
      CODE_LIST = (CODE_ALIASES.keys + CODES)

      # This is how you override default help.
      help.option(:code, "Select encoding (#{CODE_LIST})")

      # Select encoding.
      def code=(code)
        codes = CODE_LIST.select{ |x| /^#{code}/ =~ x }
        codes = codes.map{ |x| CODE_ALIASES.key?(x) ? CODE_ALIASES[x] : x }.uniq
        raise ArgumentError unless codes.size == 1
        options.encoding = codes.first
      end

      # Select transfer type (text, binary, auto).
      # Optional argument with keyword completion.
      def type=(type)
        raise ArgumentError unless %w{text binary auto}.include(type.downcase)
        options.transfer_type = type.downcase
      end

      # Run verbosely.
      # Boolean switch.
      def verbose=(bool)
        options.verbose = bool
      end
      def verbose?
        options.verbose
      end
      alias :v= :verbose=
      alias :v? :verbose?

      # Show this message.
      # No argument, shows at tail.  This will print an options summary.
      def help!
        puts self
        exit
      end

      # Show version.
      # Another typical switch to print the version.
      def version!
        puts VERSION
        exit
      end

      def main
        # ... main procedure here ...
        p options
      end
    end

    ExampleCLI.execute
```

The only signifficant difference in capability between OptionParser and Executioner
is that Executioner does not support optional switch arguments. These can easily
lead to malformed command-lines, so they were let out of Executioners specifcation.

