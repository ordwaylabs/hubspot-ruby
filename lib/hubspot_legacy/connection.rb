module HubspotLegacy
  class Connection
    include HTTParty

    class << self
      def get_json(path, opts)
        url = generate_url(path, opts)
        response = get(url, format: :json, read_timeout: read_timeout(opts), open_timeout: open_timeout(opts))
        log_request_and_response url, response
        raise(HubspotLegacy::RequestError.new(response)) unless response.success?
        response.parsed_response
      end

      def post_json(path, opts)
        no_parse = opts[:params].delete(:no_parse) { false }

        url = generate_url(path, opts[:params])
        response = post(url, { body: opts[:body].to_json, headers: { 'Content-Type' => 'application/json' }, format: :json, read_timeout: read_timeout(opts), open_timeout: open_timeout(opts) })
        log_request_and_response url, response, opts[:body]
        raise(HubspotLegacy::RequestError.new(response)) unless response.success?

        no_parse ? response : response.parsed_response
      end

      def put_json(path, options)
        url = generate_url(path, options[:params])

        response = put(
          url,
          body: options[:body].to_json,
          headers: { "Content-Type" => "application/json" },
          format: :json,
          read_timeout: read_timeout(options),
          open_timeout: open_timeout(options),
        )

        log_request_and_response(url, response, options[:body])
        handle_response(response)
      end

      def delete_json(path, opts)
        url = generate_url(path, opts)
        response = delete(url, format: :json, read_timeout: read_timeout(opts), open_timeout: open_timeout(opts))
        log_request_and_response url, response, opts[:body]
        raise(HubspotLegacy::RequestError.new(response)) unless response.success?
        response
      end

      protected

      def read_timeout(opts = {})
        opts.delete(:read_timeout) || HubspotLegacy::Config.read_timeout
      end

      def open_timeout(opts = {})
        opts.delete(:open_timeout) || HubspotLegacy::Config.open_timeout
      end

      def handle_response(response)
        if response.success?
          response.parsed_response
        else
          raise(HubspotLegacy::RequestError.new(response))
        end
      end

      def log_request_and_response(uri, response, body=nil)
        HubspotLegacy::Config.logger.info "Hubspot: #{uri}.\nBody: #{body}.\nResponse: #{response.code} #{response.body}"
      end

      def generate_url(path, params={}, options={})
        if HubspotLegacy::Config.access_token.present?
          options[:hapikey] = false
        else
          HubspotLegacy::Config.ensure! :hapikey
        end
        path = path.clone
        params = params.clone
        base_url = options[:base_url] || HubspotLegacy::Config.base_url
        params["hapikey"] = HubspotLegacy::Config.hapikey unless options[:hapikey] == false

        if path =~ /:portal_id/
          HubspotLegacy::Config.ensure! :portal_id
          params["portal_id"] = HubspotLegacy::Config.portal_id if path =~ /:portal_id/
        end

        params.each do |k,v|
          if path.match(":#{k}")
            path.gsub!(":#{k}", CGI.escape(v.to_s))
            params.delete(k)
          end
        end
        raise(HubspotLegacy::MissingInterpolation.new("Interpolation not resolved")) if path =~ /:/

        query = params.map do |k,v|
          v.is_a?(Array) ? v.map { |value| param_string(k,value) } : param_string(k,v)
        end.join("&")

        path += path.include?('?') ? '&' : "?" if query.present?
        base_url + path + query
      end

      # convert into milliseconds since epoch
      def converted_value(value)
        value.is_a?(Time) ? (value.to_i * 1000) : CGI.escape(value.to_s)
      end

      def param_string(key,value)
        case key
        when /range/
          raise "Value must be a range" unless value.is_a?(Range)
          "#{key}=#{converted_value(value.begin)}&#{key}=#{converted_value(value.end)}"
        when /^batch_(.*)$/
          key = $1.gsub(/(_.)/) { |w| w.last.upcase }
          "#{key}=#{converted_value(value)}"
        else
          "#{key}=#{converted_value(value)}"
        end
      end
    end
  end

  class FormsConnection < Connection
    follow_redirects true

    def self.submit(path, opts)
      url = generate_url(path, opts[:params], { base_url: 'https://forms.hubspot.com', hapikey: false })
      post(url, body: opts[:body], headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
    end
  end

  class FilesConnection < Connection
    follow_redirects true

    class << self
      def get(path, opts)
        url = generate_url(path, opts)
        response = super(url, read_timeout: read_timeout(opts), open_timeout: open_timeout(opts))
        log_request_and_response url, response
        raise(HubspotLegacy::RequestError.new(response)) unless response.success?
        response.parsed_response
      end

      def post(path, opts)
        url = generate_url(path, opts[:params])
        response = super(
          url,
          body: opts[:body],
          headers: { 'Content-Type' => 'multipart/form-data' },
          read_timeout: read_timeout(opts), open_timeout: open_timeout(opts)
        )
        log_request_and_response url, response, opts[:body]
        raise(HubspotLegacy::RequestError.new(response)) unless response.success?

        response
      end
    end
  end
end
