module AuthenticateService
  extend self

  def perform(installation_id)
    request = access_tokens_request(installation_id)

    response = access_tokens_response(request)

    return JSON.parse(response.body)["token"] if response.code.to_i == 201

    raise "#{response.code} #{response.body}"
  end

  private

  def access_tokens_request(installation_id)
    uri = URI.parse("https://api.github.com/installations/#{installation_id}/access_tokens")
    request = Net::HTTP::Post.new(uri.path)
    request["Authorization"] = "Bearer #{GenerateGithubAppsJwtService.perform}"
    request["Accept"] = "application/vnd.github.machine-man-preview+json"
    request
  end

  def access_tokens_response(request)
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.start do |h|
      h.request(request)
    end
  end
end
