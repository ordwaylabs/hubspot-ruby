describe HubspotLegacy::Connection do
  before(:each) do
    @url           = 'http://localhost:3000'
    @http_response = mock('http_response')
  end

  describe '.get_json' do
    it 'delegates url format to HubspotLegacy::Utils, call HTTParty get and returns response' do
      @http_response.success? { true }
      @http_response.parsed_response { {} }
      @http_response.code { 200 }
      @http_response.body { 'mocked response' }

      mock(HubspotLegacy::Connection).generate_url(@url, {}) { @url }
      mock(HubspotLegacy::Connection).get(@url, format: :json, read_timeout: nil, open_timeout: nil) { @http_response }
      HubspotLegacy::Connection.get_json(@url, {})
    end
  end

  describe '.post_json' do
    it 'delegates url format to HubspotLegacy::Utils, call HTTParty post and returns response' do
      @http_response.success? { true }
      @http_response.parsed_response { {} }
      @http_response.code { 200 }
      @http_response.body { 'mocked response' }

      mock(HubspotLegacy::Connection).generate_url(@url, {}) { @url }
      mock(HubspotLegacy::Connection).post(@url, body: "{}", headers: {"Content-Type"=>"application/json"}, format: :json, read_timeout: nil, open_timeout: nil) { @http_response }
      HubspotLegacy::Connection.post_json(@url, params: {}, body: {})
    end
  end

  describe '.delete_json' do
    it 'delegates url format to HubspotLegacy::Utils, call HTTParty delete and returns response' do
      @http_response.success? { true }
      @http_response.code { 200 }
      @http_response.body { 'mocked response' }

      mock(HubspotLegacy::Connection).generate_url(@url, {}) { @url }
      mock(HubspotLegacy::Connection).delete(@url, format: :json, read_timeout: nil, open_timeout: nil) { @http_response }
      HubspotLegacy::Connection.delete_json(@url, {})
    end
  end

  context 'private methods' do
    describe ".generate_url" do
      let(:path){ "/test/:email/profile" }
      let(:params){{email: "test"}}
      let(:options){{}}
      subject{ HubspotLegacy::Connection.send(:generate_url, path, params, options) }
      before{ HubspotLegacy.configure(hapikey: "demo", portal_id: "62515") }

      it "doesn't modify params" do
        expect{ subject }.to_not change{params}
      end

      context "with a portal_id param" do
        let(:path){ "/test/:portal_id/profile" }
        let(:params){{}}
        it{ should == "https://api.hubapi.com/test/62515/profile?hapikey=demo" }
      end

      context "when configure hasn't been called" do
        before{ HubspotLegacy::Config.reset! }
        it "raises a config exception" do
          expect{ subject }.to raise_error HubspotLegacy::ConfigurationError
        end
      end

      context "with interpolations but no params" do
        let(:params){{}}
        it "raises an interpolation exception" do
          expect{ subject }.to raise_error HubspotLegacy::MissingInterpolation
        end
      end

      context "with an interpolated param" do
        let(:params){ {email: "email@address.com"} }
        it{ should == "https://api.hubapi.com/test/email%40address.com/profile?hapikey=demo" }
      end

      context "with multiple interpolated params" do
        let(:path){ "/test/:email/:id/profile" }
        let(:params){{email: "email@address.com", id: 1234}}
        it{ should == "https://api.hubapi.com/test/email%40address.com/1234/profile?hapikey=demo" }
      end

      context "with query params" do
        let(:params){{email: "email@address.com", id: 1234}}
        it{ should == "https://api.hubapi.com/test/email%40address.com/profile?id=1234&hapikey=demo" }

        context "containing a time" do
          let(:start_time) { Time.now }
          let(:params){{email: "email@address.com", id: 1234, start: start_time}}
          it{ should == "https://api.hubapi.com/test/email%40address.com/profile?id=1234&start=#{start_time.to_i * 1000}&hapikey=demo" }
        end

        context "containing a range" do
          let(:start_time) { Time.now }
          let(:end_time) { Time.now + 1.year }
          let(:params){{email: "email@address.com", id: 1234, created__range: start_time..end_time }}
          it{ should == "https://api.hubapi.com/test/email%40address.com/profile?id=1234&created__range=#{start_time.to_i * 1000}&created__range=#{end_time.to_i * 1000}&hapikey=demo" }
        end

        context "containing an array of strings" do
          let(:path){ "/test/emails" }
          let(:params){{batch_email: %w(email1@example.com email2@example.com)}}
          it{ should == "https://api.hubapi.com/test/emails?email=email1%40example.com&email=email2%40example.com&hapikey=demo" }
        end
      end

      context "with options" do
        let(:options){ {base_url: "https://cool.com", hapikey: false} }
        it{ should == "https://cool.com/test/test/profile"}
      end

      context "passing Array as parameters for batch mode, key is prefixed with batch_" do
        let(:path) { HubspotLegacy::ContactList::LIST_BATCH_PATH }
        let(:params) { { batch_list_id: [1,2,3] } }
        it{ should == "https://api.hubapi.com/contacts/v1/lists/batch?listId=1&listId=2&listId=3&hapikey=demo" }
      end
    end
  end
end
