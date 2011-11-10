# This code is a derivation of Dmitry Elastic work
# in the method_source gem.

class UnboundMethod

  if !method_defined?(:source_location)

    if Proc.method_defined? :__file__
      # Ruby enterprise edition provides all the information that's
      # needed, in a slightly different way.
      def source_location
        [__file__, __line__] rescue nil
      end

    elsif defined?(RUBY_ENGINE) && RUBY_ENGINE =~ /jruby/
      require 'java'

      # JRuby version source_location hack
      # @return [Array] A two element array containing the source location of the method
      def source_location
        to_java.source_location(Thread.current.to_java.getContext())
      end

    else

      # Return the source location of an instance method for Ruby 1.8.
      # @return [Array] A two element array. First element is the
      #   file, second element is the line in the file where the
      #   method definition is found.
      def source_location
        klass = case owner
                when Class
                  owner
                when Module
                  method_owner = owner
                  Class.new { include(method_owner) }
                end

        # deal with immediate values
        case
        when klass == Symbol
          return :a.method(name).source_location
        when klass == Fixnum
          return 0.method(name).source_location
        when klass == TrueClass
          return true.method(name).source_location
        when klass == FalseClass
          return false.method(name).source_location
        when klass == NilClass
          return nil.method(name).source_location
        end

        begin
          klass.allocate.method(name).source_location
        rescue TypeError

          # Assume we are dealing with a Singleton Class:
          # 1. Get the instance object
          # 2. Forward the source_location lookup to the instance
          instance ||= ObjectSpace.each_object(owner).first
          instance.method(name).source_location
        end
      end

    end

  end

end
