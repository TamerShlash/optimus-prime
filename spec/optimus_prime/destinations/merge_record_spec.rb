require 'spec_helper'
require 'optimus_prime/destinations/merge_record'

module OptimusPrime
  module Sources
    class MySource < OptimusPrime::Source
      def initialize(events:); @events = events; end
      def each; @events.each { |event| yield event }; end
    end
  end

  module Destinations
    class MyDestination < OptimusPrime::Destination
      attr_reader :written
      def write(record)
        @received = record
      end

      def finish; @written = @received; end
    end
  end
end

describe OptimusPrime::Destinations::MergeRecord do
  let(:inputs) do
    [[{ Platform: 'android', Level: 1, Percent: 0.0 },
     { Platform: 'ios', Level: 1, Percent: 19.2 },
     { Platform: 'android', Level: 2, Percent: 4.2 },
     { Platform: 'android', Level: 3, Percent: 2.9 }],
    [{ Platform: 'android', Level: 1, MinScore: 2034 },
     { Platform: 'ios', Level: 1, MinScore: 1000 },
     { Platform: 'android', Level: 1, HighScore: 55555 }],
    [{ Platform: 'ios', Level: 1, Fail: 2 }]]
  end

  let(:output) do
    [{ Platform: 'android', Level: 1, Percent: 0.0, MinScore: 2034, HighScore: 55555 },
     { Platform: 'android', Level: 2, Percent: 4.2 },
     { Platform: 'android', Level: 3, Percent: 2.9 },
     { Platform: 'ios', Level: 1, Percent: 19.2, MinScore: 1000, Fail: 2 }]
  end

  let(:sources) do
    Hash[inputs.map.with_index do |input, idx|
      ["src_#{idx}".to_sym, {
        class: 'OptimusPrime::Sources::MySource',
        params: { events: input },
        next: ['trans_c']
      }]
    end]
  end

  let(:pipeline) do
    OptimusPrime::Pipeline.new(**{
      trans_c: {
        class: 'OptimusPrime::Destinations::MergeRecord',
        params: { join_keys: [:Platform, :Level] },
        next: ['dest_d']
      },
      dest_d: { class: 'OptimusPrime::Destinations::MyDestination' }
    }.merge(sources))
  end

  it 'should merge a record to an array of hash' do
    pipeline.start
    expect(pipeline.started?).to be true
    expect(pipeline.finished?).to be false
    pipeline.wait
    expect(pipeline.finished?).to be true
    @results = pipeline.steps.values_at(:dest_d)[0].written
    expect(@results).to match_array output
  end
end
