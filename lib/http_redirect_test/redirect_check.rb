require 'uri'
require 'excon'
require "excon/middlewares/redirect_follower"

class RedirectCheck
  attr_reader :source_path, :destination_path, :options, :headers, :header, :body

  def initialize(domain, source_path, destination_path = nil, options={})
    @domain = domain
    @options = options
    @source_path = source_path.to_s
    @destination_path = destination_path.to_s
  end

  def uri
    URI.parse("#{scheme}://#{raw_domain}#{source_path}")
  end

  def source_uri
    @source_uri ||= (uri.query.nil?) ? uri.path : uri.path + "?" + uri.query
  end

  def connection
    port = uri.port != 80 ? ":#{uri.port}" : ""
    @connection = Excon.new("#{scheme}://#{raw_domain}", headers: options[:headers] || {})
  end

  def response
    @response ||= connection.get(path: source_uri)
  end

  def success?
    response.status == 200
  end

  def gone?
    response.status == 410
  end

  def not_found?
    response.status == 404
  end

  def permanent_redirect?
    response.status == 301
  end

  def redirected?
    [300, 301, 302, 303].include?(response.status)
  end

  def redirected_path
    response.headers['location'].sub(/#{Regexp.escape("#{uri.scheme}://#{uri.host}")}:#{uri.port}/, '') if redirected?
  end

  def header(name)
    response.headers[name]
  end

  def headers
    response.headers
  end

  def body
    response.body
  end

  private

  def scheme
    if domain_components.length == 2
      scheme = domain_components.first
    end

    scheme || 'http'
  end

  def raw_domain
    domain_components.last
  end

  def ssl?
    scheme == 'https'
  end

  def domain_components
    @domain_components ||= @domain.split('://')
  end
end
