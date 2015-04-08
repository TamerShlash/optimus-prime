require 'spec_helper'

module OptimusPrime
  module Sources
    class Test < OptimusPrime::Source
      def initialize(data:, delay: 0)
        @data = data
        @delay = delay
      end

      def each
        sleep @delay
        @data.each { |i| yield i }
      end
    end
  end

  module Destinations
    class Test < OptimusPrime::Destination
      attr_reader :written
      def write(record)
        @received ||= []
        @received << record
      end

      def finish
        @written = @received
      end
    end
  end
end

class IncrementStep < OptimusPrime::Destination
  def write(data)
    sleep 0.1
    data['value'] += 1
    push data
  end
end

class DoubleStep < OptimusPrime::Destination
  def write(data)
    data['value'] *= 2
    push data
  end
end

describe OptimusPrime::Pipeline do
  #     a   b
  #     |   |
  #     c   d
  #      \ /
  #       e
  #      / \
  #     f   g

  def data_for(range)
    range.map do |i|
      { 'value' => i }
    end
  end

  let(:pipeline) do
    OptimusPrime::Pipeline.new(
      a: {
        class: 'OptimusPrime::Sources::Test',
        params: { data: data_for(1..10), delay: 1 },
        next: ['c']
      },
      b: {
        class: 'OptimusPrime::Sources::Test',
        params: { data: data_for(100..110) },
        next: ['d']
      },
      c: {
        class: 'DoubleStep',
        next: ['e']
      },
      d: {
        class: 'IncrementStep',
        next: ['e']
      },
      e: {
        class: 'DoubleStep',
        next: ['f', 'g']
      },
      f: {
        class: 'OptimusPrime::Destinations::Test'
      },
      g: {
        class: 'OptimusPrime::Destinations::Test'
      }
    )
  end

  describe '#start' do
    it 'should run the pipeline' do
      pipeline.start
      expect(pipeline.started?).to be true
      expect(pipeline.finished?).to be false
      pipeline.wait
      expect(pipeline.finished?).to be true
      expected = (4..40).step(4).to_a + (202..222).step(2).to_a
      pipeline.steps.values_at(:f, :g).each do |destination|
        actual = destination.written.map { |record| record['value'] }
        expect(actual).to match_array expected
      end
    end

    it 'should fail when called twice' do
      pipeline.start
      expect { pipeline.start }.to raise_error
    end
  end
end
