require 'test/unit'
require 'executioner'

class TC_Executioner < Test::Unit::TestCase

  class MyCommand < Executioner
    attr_reader :size, :quiet, :file

    def initialize
      @file = 'hey.txt' # default
    end

    #use :quiet, "supress standard output", :type => :boolean

    #def __quiet(bool=true)
    #  @quiet = bool ? true : bool
    #end

    def quiet?
      @quiet = true
    end

    #use :size, "what size will it be?", :type => :integer, :default => '0'

    #def __size(integer)
    #  @size = integer.to_i
    #end

    def size=(integer)
      @size = integer.to_i
    end

    #use :file, "where to store the stuff", :init => 'hey.txt'

    #def __file(fname)
    #  @file = fname
    #nd

    def file=(fname)
      @file = fname
    end

    def command_missing
    end

    #def call(*args)
    #  @args = args
    #end
  end


  def setup
    @mc = MyCommand.new
  end

  def test_boolean_optiion
    @mc.run('--quiet')
    assert(@mc.quiet)
  end

  def test_integer_optiion
    @mc.run('--size=4')
    assert_equal(4, @mc.size)
  end

  def test_default_value
    @mc.run('')
    assert_equal('hey.txt', @mc.file)
  end

  def usage_output
    MyCommand.usage.assert == "--quiet=BOOLEAN --size=INTEGER --file=VALUE"
  end

end

