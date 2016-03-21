shared_context "stub_query", :query do
  let(:client) { Influxer.client }

  before do
    # Stub all query methods
    allow_any_instance_of(InfluxDB::Client).to receive(:query) do |_, sql|
      sql
    end

    allow_any_instance_of(InfluxDB::Client).to receive(:time_precision)

    allow_any_instance_of(InfluxDB::Client).to receive(:post)
  end
end
