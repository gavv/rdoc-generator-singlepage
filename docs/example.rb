module Foo
  def foo
    puts 'fooooo!'
  end
end

class Bar
  include Foo
  
  def self.bar
  end
end

class Baz
  extend Foo
end