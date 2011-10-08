module Executioner
  #
  DIRECTORY = File.dirname(__FILE__)

  #
  def self.version
    @package ||= (
      require 'yaml'
      YAML.load(File.new(DIRECTORY + '/version.yml'))
    )
  end

  #
  #def self.profile
  #  @profile ||= (
  #    require 'yaml'
  #    YAML.load(File.new(DIRECTORY + '/profile.yml'))
  #  )
  #end

  #
  def self.const_missing(name)
    key = name.to_s.downcase
    #version[key] || profile[key] || super(name)
    version[key] super(name)
  end

  # becuase Ruby 1.8~ gets in the way
  remove_const(:VERSION) if const_defined?(:VERSION)
end

