module GenerateGithubAppsJwtService
  extend self
  def perform
    private_pem = ENV["PRIVATE_PEM"]
    private_key = OpenSSL::PKey::RSA.new(private_pem)
    JWT.encode(payload, private_key, "RS256")
  end

  private

  def payload
    {
      # issued at time
      iat: Time.now.getutc.to_i - 5.seconds.to_i,
      # JWT expiration time (10 minute maximum)
      exp: 10.minutes.from_now.getutc.to_i - 5.seconds.to_i,
      # Integration's GitHub identifier
      iss: 2713
    }
  end
end
