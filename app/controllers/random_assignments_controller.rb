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

    pr_user_id = http.execute(<<-USER)["data"]["user"]["id"]
    query {
      user(login: "#{pr_user_login}") {
        id
      }
    }
    USER

    result = http.execute(document: <<-QUERY)
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

    raise result["errors"].first["message"] if result["errors"]

    pr_id = result["data"]["repository"]["pull_request"]["id"]
    member_ids = result["data"]["repository"]["mentionableUsers"]["nodes"].map{ |node|node["id"] }
    member_ids.delete(pr_user_id)

    variables = {"r":
      {
        "pullRequestId": pr_id,
        "userIds": "[#{member_ids.sample}]"
      }
    }
    mutation_result = http.execute(document: <<-MUTATION, variables: variables)
      mutation RequestReview($r: RequestReviewsInput!) {
        requestReviews(input: $r) {
          clientMutationId
        }
      }
    MUTATION

    raise mutation_result["errors"].first["message"] if mutation_result["errors"]
  end
end
