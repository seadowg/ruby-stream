class Stream
  def self.continually(&block)
    Stream.new(yield) do
      Stream.continually(&block)
    end
  end

  attr_reader :head

  def initialize(head, &block)
    @head = head
    @tail_block = block
  end

  def tail
    @tail_block.call
  end

  def last
    result = nil
    self.each do |ele|
      result = ele
    end

    result
  end

  def [](n)
    if n == 0
      self.head
    elsif n < 0
      nil
    else
      last_stream = self
      n.times {
        return nil if last_stream.kind_of?(EmptyStream)
        last_stream = last_stream.tail
      }

      last_stream.head
    end
  end

  def length
    counter = 0
    self.each { |ele| counter += 1 }
    counter
  end

  def each(&block)
    last_stream = self

    until last_stream.kind_of?(EmptyStream)
      block.call(last_stream.head)
      last_stream = last_stream.tail
    end

    nil
  end

  def take(n)
    if n <= 0
      EmptyStream.new
    else
      Stream.new(head) do
        tail.take(n - 1)
      end
    end
  end

  def take_while(&block)
    if block.call(head)
      Stream.new(head) do
        tail.take_while(&block)
      end
    else
      EmptyStream.new
    end
  end

  def drop(n)
    if n <= 0
      Stream.new(head) do
        tail
      end
    else
      tail.drop(n - 1)
    end
  end

  def map(&block)
    Stream.new(yield head) do
      tail.map(&block)
    end
  end

  def scan(zero, &block)
    Stream.new(zero) do
      tail.scan(block.call(zero, head), &block)
    end
  end

  def fold_left(*args, &block)
    zero = args[0]
    symbol = args[1] || args[0]

    scan = if block
      self.scan(zero, &block)
    elsif args.length == 2
      self.scan(zero, &symbol.to_proc)
    elsif args.length == 1
      self.drop(1).scan(head, &symbol.to_proc)
    end

    scan.last
  end

  alias :inject :fold_left
  alias :reduce :fold_left

  def filter(&block)
    if block.call(head)
      Stream.new(head) do
        tail.filter(&block)
      end
    else
      tail.filter(&block)
    end
  end

  class EmptyStream < Stream
    def initialize()
      @head = nil
    end

    def tail
      EmptyStream.new
    end

    def last
      nil
    end

    def [](n)
      nil
    end

    def each
      nil
    end

    def take(n)
      EmptyStream.new
    end

    def drop(n)
      EmptyStream.new
    end

    def take_while(&block)
      EmptyStream.new
    end

    def map(&block)
      EmptyStream.new
    end

    def filter(&block)
      EmptyStream.new
    end

    def scan(zero, &block)
      Stream.new(zero) do
        EmptyStream.new
      end
    end
  end
end
