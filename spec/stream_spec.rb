require 'spec_helper'
require 'matilda-stream'

describe Stream do
  before do
    int_helper = lambda { |i|
      Stream.new(i) {
        int_helper.call(i + 1)
      }
    }

    @stream = int_helper.call(1)
  end

  describe "#head" do
    it "returns the first element of the Stream" do
      @stream.head.must_equal 1
    end
  end

  describe "#tail" do
    it "returns another Stream" do
      @stream.tail.kind_of?(Stream).must_equal true
    end

    it "returns a Stream with the next element as its head" do
      @stream.tail.head.must_equal 2
      @stream.tail.tail.head.must_equal 3
    end
  end

  describe "#last" do
    it "returns the last element for finite Stream" do
      @stream.take(5).last.must_equal 5
    end
  end

  describe "#[](n)" do
    it "calculates the nth element of the stream" do
      @stream[999].must_equal 1000
    end

    it "returns nil for negative n" do
      @stream[-1].must_equal nil
    end

    describe "for a finite Stream" do
      it "returns nil for n greater than the limit of the Stream" do
        @stream.take(10)[10].must_equal nil
      end
    end
  end

  describe "#take(n)" do
    it "returns another Stream" do
      @stream.take(10).kind_of?(Stream).must_equal true
    end

    it "returns a Stream with the correct #length" do
      @stream.take(10).length.must_equal 10
    end

    it "returns a Stream with the correct values" do
      stream = @stream.take(10)
      stream[0].must_equal 1
      stream[5].must_equal 6
      stream[7].must_equal 8
      stream[9].must_equal 10
    end

    it "returns a Stream that can be iterated through finitely" do
      @stream.take(10).each do |element|
        true.must_equal true
      end
    end

    describe "when operating on the result Stream" do
      it "returns a finite Stream for #map" do
        stream = @stream.take(10).map { |i| i.to_s }
        stream.length.must_equal 10
      end

      it "returns a finite Stream for #filter" do
        stream = @stream.take(10).filter { |i| true }
        stream.length.must_equal 10
      end
    end

    describe "for a finite Stream" do
      it "returns a Stream with length limit if n > limit" do
        original = @stream.take(10)
        original.take(100).length.must_equal 10
      end
    end
  end

  describe "#drop(n)" do
    it "returns another Stream" do
      @stream.drop(1).kind_of?(Stream).must_equal true
    end

    it "returns a Stream that skips the first n elements of the original" do
      stream = @stream.drop(5)
      stream[0].must_equal 6
      stream[1].must_equal 7
    end

    describe "for a finite Stream" do
      it "returns a Stream with the correct length" do
        @stream.take(5).drop(1).length.must_equal 4
      end
    end
  end

  describe "#each(func)" do
    describe "for a finite Stream" do
      it "should return nil" do
        @stream.take(5).each do
          1
        end.must_equal nil
      end

      it "should execute the passed block for every element of the stream" do
        i = 0
        @stream.take(5).each do
          i += 1
        end

        i.must_equal 5
      end
    end
  end

  describe "#length" do
    it "returns the lenght for a finite array" do
      @stream.take(5).length.must_equal 5
    end
  end

  describe "#map(func)" do
    it "returns a new Stream" do
      @stream.map(&:to_s).kind_of?(Stream).must_equal true
    end

    it "returns a new Stream with mapped values" do
      mapped = @stream.map { |i| i + 1 }
      mapped[0].must_equal(2)
      mapped[3].must_equal(5)
      mapped[1000].must_equal(1002)
    end
  end

  describe "#filter(func)" do
    it "returns a new Stream" do
      @stream.filter { |i| i % 2 == 0 }.kind_of?(Stream).must_equal true
    end

    it "returns a new Stream with only elements matching the predicate" do
      filtered = @stream.filter { |i| i % 2 == 0 }
      filtered[0].must_equal 2
      filtered[1].must_equal 4
      filtered[3].must_equal 8
    end
  end

  describe "#take_while(func)" do
    it "returns a new Stream" do
      @stream.take_while { |i| i < 10 }.kind_of?(Stream).must_equal true
    end

    describe "when the return Stream is finite" do
      it "returns a Stream with the correct length" do
        @stream.take_while { |i| i < 10 }.length.must_equal 9
      end

      it "returns a Stream that iterates through finitely" do
        stream = @stream.take_while { |i| i < 10 }
        counter = 0
        stream.each { |i| counter += 1 }
        counter.must_equal 9
      end

      it "returns a finite Stream for #map" do
        stream = @stream.take_while { |i|
          i < 10
        }.map { |i| i.to_s }

        stream.length.must_equal 9
      end

      it "returns a finite Stream for #filter" do
        stream = @stream.take_while { |i|
          i < 10
        }.filter { |i| true }

        stream.length.must_equal 9
      end
    end
  end

  describe "#scan(zero, func)" do
    it "returns a new Stream" do
      @stream.scan(0) { |x, i| i }.kind_of?(Stream).must_equal true
    end

    it "returns a Stream with a head equivelant to the passed zero" do
      @stream.scan(-1) { |x, i| i }.head.must_equal -1
    end

    it "returns a Stream that is the scan of the receiver" do
      scan = @stream.scan(0) { |x, i| x + i }
      scan[1].must_equal(1)
      scan[2].must_equal(3)
      scan[3].must_equal(6)
      scan[100].must_equal(5050)
    end

    it "works correctly with finite streams" do
      scan = @stream.take(1).scan(0) { |x, i| x + i }
      scan[1].must_equal 1
    end
  end

  describe "#fold_left(zero, func)" do
    it "returns the left fold for an finite Stream" do
      sum = @stream.take(5).fold_left(1) { |memo, ele|
        memo + ele
      }
      sum.must_equal 16
    end

    it "returns the zero value for empty lists" do
      value = @stream.take(0).fold_left(101) { |i, j| j }
      value.must_equal 101
    end

    it "allows the func to be a symbol" do
      sum = @stream.take(5).fold_left(1, :+)
      sum.must_equal 16
    end

    it "is aliased with 'inject'" do
      @stream.method(:fold_left).must_equal @stream.method(:inject)
    end

    it "is aliased with 'reduce'" do
      @stream.method(:fold_left).must_equal @stream.method(:reduce)
    end
  end

  describe "#fold_left(symbol)" do
    it "returns the left fold for a finite Stream but skips the zero value step" do
      sum = @stream.take(5).fold_left(:+)
      sum.must_equal 15
    end

    it "returns nil for an empty Stream" do
      sum = @stream.take(0).fold_left(:+)
      sum.must_equal nil
    end
  end

  describe ".continually(func)" do
    it "returns a new Stream" do
      Stream.continually {
        true
      }.kind_of?(Stream).must_equal true
    end

    it "returns a Stream with the calculated block as each element" do
      stream_block = Proc.new do
        counter = 0
        Stream.continually {
          counter += 1
        }
      end

      stream_block.call.head.must_equal 1
      stream_block.call.tail.head.must_equal 2
      stream_block.call.tail.tail.head.must_equal 3
    end
  end

  describe "EmptyStream" do
    it "ends the Stream" do
      stream = lambda { |i|
        Stream.new(i) do
          if i < 1
            Stream::EmptyStream.new
          else
            stream.call(i - 1)
          end
        end
      }

      stream.call(10).length.must_equal(11)
    end
  end
end
