module AuthenticateService
  extend self

  def perform(installation_id)
    require 'net/http'
    require 'uri'

    uri = URI.parse("https://api.github.com/installations/#{installation_id}/access_tokens")
    request = Net::HTTP::Post.new(uri.path)
    request["Authorization"] = "Bearer #{GenerateGithubAppsJwtService.perform}"
    request["Accept"] = "application/vnd.github.machine-man-preview+json"

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.set_debug_output($stdout)
    response = http.start do |h|
      h.request(request)
    end
    if response.code.to_i == 201
      return JSON.parse(response.body)["token"]
    else
      raise "#{response.code} #{response.body}"
    end
  end
end
