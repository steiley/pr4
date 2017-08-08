class RandomAssignmentsController < ApplicationController
  def create
    payload = JSON.parse(request.body.read)
    head :success unless %w(open reopen).include?(payload["action"])

    pr_user_login = payload["pull_request"]["user"]["login"]
    http = GraphQL::Client::HTTP.new("https://api.github.com/graphql")do
      attr_writer :token

      def headers(_context)
        {
         Authorization: "token #{@token}",
         Accept: "application/vnd.github.machine-man-preview+json"
        }
      end
    end
    http.token = AuthenticateService.perform(payload["installation"]["id"])

    repository_owner = payload["repository"]["owner"]["login"]
    pr_number = payload["pull_request"]["number"]
    repository_info = graphql_http_execute(http, <<-QUERY)["repository"]
         query {
           repository(owner: "#{repository_owner}", name: "#{payload["repository"]["name"]}") {
             pullRequest(number: #{pr_number}) {
               id
             }
             mentionableUsers(last: 10) {
               nodes {
                 login
               }
             }
           }
         }
    QUERY

    member_logins = repository_info["mentionableUsers"]["nodes"].map{ |node|node["login"] }
    member_logins.delete(pr_user_login)
    member_logins.delete("pr3-bot")

    conn = Faraday.new(url: "https://api.github.com/") do |faraday|
      faraday.basic_auth("pr3-bot", IO.read("pr3-bot.key").strip)
      faraday.response :logger, Rails.logger
      faraday.adapter :net_http
    end

    owner_login = payload["repository"]["owner"]["login"]
    faraday_response = conn.post do |req|
      req.url("/repos/#{owner_login}/#{payload["repository"]["name"]}/pulls/#{pr_number}/requested_reviewers")

      req.headers["Accept"] = "application/vnd.github.thor-preview+json"
      req.body = JSON.generate({
        reviewers: [
          member_logins.sample
        ]
      }
      )
    end

    if faraday_response.status == 201
      render json: {status: :ok}
    else
      raise %Q(#{response.status}:#{response.body})
    end
  end

  private
  def graphql_http_execute(http, document, variables = {})
    response = http.execute(document: document, variables: variables)
    if response["errors"]
      raise response["errors"].first["message"]
    else
      response["data"]
    end
  end
end
