require 'spec_helper'
require 'optimus_prime/sources/bigquery'

describe OptimusPrime::Sources::Bigquery do
  describe '#each' do
    let(:response_rows) do
      [
        { 'f' => [
          { 'v' => nil },
          { 'v' => 'android' },
          { 'v' => '0.0' },
          { 'v' => '88550' },
          { 'v' => 'true' }
        ] },
        { 'f' => [
          { 'v' => 'a' },
          { 'v' => nil },
          { 'v' => '4.2' },
          { 'v' => '28200' },
          { 'v' => 'false' }
        ] },
        { 'f' => [
          { 'v' => 'b' },
          { 'v' => 'android' },
          { 'v' => nil },
          { 'v' => '47325' },
          { 'v' => 'true' }
        ] },
        { 'f' => [
          { 'v' => 'b' },
          { 'v' => 'android' },
          { 'v' => '2.15' },
          { 'v' => nil },
          { 'v' => 'false' }
        ] },
        { 'f' => [
          { 'v' => 'b' },
          { 'v' => 'android' },
          { 'v' => '42.9' },
          { 'v' => '128175' },
          { 'v' => nil }
        ] }
      ]
    end

    let(:project_id) { 'project-id' }
    let(:job_id) { 'job-id' }
    let(:query_response) do
      {
        'kind' => 'bigquery#queryResponse',
        'schema' => {
          'fields' => [{ 'name' => 'Game', 'type' => 'STRING', 'mode' => 'NULLABLE' },
                       { 'name' => 'Platform', 'type' => 'STRING', 'mode' => 'NULLABLE' },
                       { 'name' => 'PercentComplete', 'type' => 'FLOAT', 'mode' => 'NULLABLE' },
                       { 'name' => 'MinScore', 'type' => 'INTEGER', 'mode' => 'NULLABLE' },
                       { 'name' => 'IsTester', 'type' => 'BOOLEAN', 'mode' => 'NULLABLE' }]
        },
        'jobReference' => { 'projectId' => project_id, 'jobId' => job_id },
        'totalRows' => response_rows.count.to_s,
        'rows' => response_rows,
        'totalBytesProcessed' => '1200',
        'jobComplete' => true,
        'cacheHit' => false
      }
    end

    let(:results) do
      [{ Game: nil, Platform: 'android', PercentComplete: 0.0, MinScore: 88_550, IsTester: true },
       { Game: 'a', Platform: nil, PercentComplete: 4.2, MinScore: 28_200, IsTester: false },
       { Game: 'b', Platform: 'android', PercentComplete: nil, MinScore: 47_325, IsTester: true },
       { Game: 'b', Platform: 'android', PercentComplete: 2.15, MinScore: nil, IsTester: false },
       { Game: 'b', Platform: 'android', PercentComplete: 42.9, MinScore: 128_175, IsTester: nil }]
    end

    let(:sql) do
      %{ SELECT Game, Platform, PercentComplete, MIN(Score) AS MinScore, IsTester
         FROM [dataset.table];
      }
    end

    def stub_get_query_results(rows, request_page_token, next_page_token)
      response = query_response.clone
      response['rows'] = rows
      response['pageToken'] = next_page_token if next_page_token
      allow(GoogleBigquery::Jobs).to receive(:getQueryResults)
        .with(project_id, job_id, request_page_token)
        .and_return(response)
    end

    let(:source) do
      OptimusPrime::Sources::Bigquery.new project_id: project_id,
                                          sql: sql,
                                          pass_phrase: 'notasecret',
                                          key_file: 'test-privatekey.p12',
                                          email: 'test@developer.gserviceaccount.com'
    end

    before :each do
      allow(GoogleBigquery::Auth).to receive_message_chain(:new, :authorize).and_return(true)
    end

    context 'one page result' do
      it 'should yield all results' do
        allow(GoogleBigquery::Jobs).to receive(:query).and_return(query_response)
        expect(source.to_a).to eq(results)
      end
    end

    context 'multiple pages result' do
      it 'should yield all results' do
        incomplete_query_response = query_response.select do |k, v|
          ['kind', 'jobReference', 'jobComplete'].include? k
        end
        incomplete_query_response['jobComplete'] = false
        allow(GoogleBigquery::Jobs).to receive(:query).and_return(incomplete_query_response)

        stub_get_query_results response_rows.take(2), {}, '2'
        stub_get_query_results response_rows[2, 2], { pageToken: '2' }, '3'
        stub_get_query_results [response_rows.last], { pageToken: '3' }, nil

        expect(source.to_a).to eq(results)
      end
    end
  end
end