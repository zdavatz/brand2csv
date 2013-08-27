# encoding: utf-8

require 'stringio'
require 'ostruct'

module Kernel
  # for stdout/stderr
  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval "$#{stream} = #{stream.upcase}"
    end
    result
  end

  # for load executable file
  def exit(status=false)
    raise LoadError
  end
end

