require 'test/unit'
require 'clio/command'

class TestCommand < Test::Unit::TestCase

  class ExampleCommand < ::Clio::Command

    def setup
      @check = {}
    end

    # No arguments and no options.
    def _a
      @check['a'] = true
    end

    # Takes only option.
    def _b(opts)
      @check['b'] = opts
    end

    # Takes multiple arguments and options. (Ruby 1.9 only)
    #def c(*args, opts)
    #end

    # opt 'a', :bolean, 'example option a'

    # Takes one argument and options.
    def call(args, opts)
      @check['args'] = args
      @check['opts'] = opts
    end

  end


  def test_one
    assert(true)
  end

end

