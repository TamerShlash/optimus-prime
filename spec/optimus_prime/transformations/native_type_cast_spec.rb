require 'spec_helper'
require 'optimus_prime/transformations/native_type_cast'

RSpec.describe OptimusPrime::Destinations::NativeTypeCast do

  let(:type_map_correct)   { { 'amount' => 'integer', 'price' => 'float' } }
  let(:type_map_erroneous) { { 'amount' => 'integer', 'price' => 'lorem' } }
  let(:logfile) { '/tmp/native_type_cast.log' }
  let(:logger) { Logger.new(logfile) }

  let(:input_valid) do
    [
      { 'event' => 'buymeat',  'amount' => '23',  'price' => '299.23' },
      { 'event' => 'buybeans', 'amount' => '125', 'price' => '412.5'  }
    ]
  end

  let(:output_valid) do
    [
      { 'event' => 'buymeat',  'amount' => 23,  'price' => 299.23 },
      { 'event' => 'buybeans', 'amount' => 125, 'price' => 412.5  }
    ]
  end

  let(:input_invalid) do
    [
      { 'event' => 'buymeat',  'amount' => '23',      'price' => '299.23' },
      { 'event' => 'buybeans', 'amount' => 'nothing', 'price' => '412.5'  },
      { 'event' => 'buybeans', 'amount' => '35',      'price' => '333.5'  }
    ]
  end

  let(:outpu_invalid) do
    [
      { 'event' => 'buymeat',  'amount' => 23, 'price' => 299.23 },
      { 'event' => 'buybeans', 'amount' => 35, 'price' => 333.5  }
    ]
  end

  context 'valid input and correct type map' do
    it 'should successfully convert each value to it\'s real type' do
      caster = OptimusPrime::Destinations::NativeTypeCast.new(type_map: type_map_correct)
      caster.logger = logger
      output = []
      caster.output << output
      input_valid.each { |record| caster.write(record) }
      expect(output).to match_array output_valid
    end
  end

  context 'valid input and incorrect type map' do
    it 'should raise a TypeError exception' do
      caster = OptimusPrime::Destinations::NativeTypeCast.new(type_map: type_map_erroneous)
      caster.logger = logger
      expect { input_valid.each { |record| caster.write(record) } }.to raise_error(TypeError)
    end
  end

  context 'invalid input and correct type map' do
    before { File.delete(logfile) }
    it 'should raise a TypeError exception' do
      caster = OptimusPrime::Destinations::NativeTypeCast.new(type_map: type_map_correct)
      caster.logger = logger
      output = []
      caster.output << output
      input_invalid.each { |record| caster.write(record) }
      expect(output).to match_array outpu_invalid
      expect(File.read(logfile).lines.count).to be > 1
    end
  end

end