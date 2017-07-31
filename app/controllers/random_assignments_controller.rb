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

    pr_user_id = graphql_http_execute(http, <<-USER)["user"]["id"]
    query {
      user(login: "#{pr_user_login}") {
        id
      }
    }
    USER

    repository_owner = payload["repository"]["owner"]["login"]
    repository_info = graphql_http_execute(http, <<-QUERY)["repository"]
         query {
           repository(owner: "#{repository_owner}", name: "#{payload["repository"]["name"]}") {
             pullRequest(number: 1) {
               id
             }
             mentionableUsers(last: 10) {
               nodes {
                 id
               }
             }
           }
         }
    QUERY

    pr_id = repository_info["pullRequest"]["id"]
    member_ids = repository_info["mentionableUsers"]["nodes"].map{ |node|node["id"] }
    member_ids.delete(pr_user_id)

    mutation_variables = {"r":
      {
        "pullRequestId": pr_id,
        "userIds": "[#{member_ids.sample}]"
      }
    }
    
    graphql_http_execute(http, <<-MUTATION, mutation_variables)
      mutation RequestReview($r: RequestReviewsInput!) {
        requestReviews(input: $r) {
          clientMutationId
        }
      }
    MUTATION

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
