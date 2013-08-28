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

  alias :original_exit :exit
  # for load executable file
  def exit(status=false)
    (status == 1) ? raise(LoadError) : original_exit
  end
end

