require "crometheus"

require "../args"

abstract class Metric < Crometheus::Metric
  def initialize(@args : Config,
                 @name : Symbol,
                 @docstring : String,
                 register_with : Crometheus::Registry? = Crometheus.default_registry)
    super(@name, @docstring, register_with)
  end

  def self.type
    Type::Gauge
  end

  abstract def samples(&block : Sample -> Nil) : Nil
end
