require 'spec_helper'
require 'optimus_prime/destinations/csv'

RSpec.describe OptimusPrime::Destinations::Csv do
  aws_params = { endpoint: 'http://localhost:10001/', force_path_style: true }

  let(:s3) { Aws::S3::Client.new aws_params }

  let(:bucket) { 'ppl-csv-test' }

  let(:input) do
    [
      { 'name' => 'Bob',   'age' => 28, 'likes' => 'cheese' },
      { 'name' => 'Alice', 'age' => 34, 'likes' => 'durian' },
    ]
  end

  before :each do
    s3.create_bucket bucket: bucket
  end

  def upload(destination)
    input.each { |obj| destination.write obj }
    destination.close
  end

  def download(destination)
    object = s3.get_object bucket: bucket, key: destination.key
    CSV.new object.body, converters: :all
  end

  def hashes(header, rows)
    rows.map { |row| header.zip(row).to_h }
  end

  def test(csv)
    header = csv.first
    expect(header).to eq destination.fields
    expect(hashes(header, csv)).to eq input.map { |row| row.select { |k, v| header.include? k } }
  end

  def test_upload(destination)
    upload destination
    test download destination
  end

  it 'should upload csv to s3' do
    destination = OptimusPrime::Destinations::Csv.new fields: ['name', 'age'],
                                                      bucket: bucket,
                                                      key: 'people.csv',
                                                      **aws_params
    test_upload destination
  end

  it 'should upload csv to s3 in chunks' do
    destination = OptimusPrime::Destinations::Csv.new fields: ['name', 'age'],
                                                      bucket: bucket,
                                                      key: 'people-chunks.csv',
                                                      chunk_size: 5,
                                                      **aws_params
    test_upload destination
  end
end
