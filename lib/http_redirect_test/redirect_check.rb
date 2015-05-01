require 'uri'
require 'excon'

class RedirectCheck
  attr_reader :source_path, :destination_path

  def initialize(domain, source_path, destination_path = nil)
    @domain = domain
    @source_path = source_path.to_s
    @destination_path = destination_path.to_s
  end

  def uri
    URI.parse("#{scheme}://#{raw_domain}#{source_path}")
  end

  def source_uri
    @source_uri ||= (uri.query.nil?) ? uri.path : uri.path + "?" + uri.query
  end

  def response
    @response ||= Excon.get(source_uri)
  end

  def success?
    response.is_a?(Excon::OK)
  end

  def gone?
    response.is_a?(Excon::Gone)
  end

  def not_found?
    response.is_a?(Excon::NotFound)
  end

  def redirected?
    response.is_a?(Excon::Found)
  end

  def permanent_redirect?
    redirected? && response.is_a?(Excon::MovedPermanently)
  end

  def redirected_path
    response.headers['location'].sub(/#{Regexp.escape("#{uri.scheme}://#{uri.host}")}:#{uri.port}/, '') if redirected?
  end

  def header(name)
    response.headers[name]
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
