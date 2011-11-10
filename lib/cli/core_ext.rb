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
    end

  end

end
