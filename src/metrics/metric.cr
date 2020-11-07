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


def execute_cmd(cmd, args)
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  status = Process.run(cmd, args: args, output: stdout, error: stderr)
  if status.success?
    {status.exit_code, stdout.to_s}
  else
    {status.exit_code, stderr.to_s}
  end
end
