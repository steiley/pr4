class RandomAssignmentsController < ApplicationController
  def create
    payload = JSON.parse(request.body.read)
    head :success unless %w(open reopen).include?(payload["action"])

    repository_owner = payload["repository"]["owner"]["login"]
    pr_owner = payload["pull_request"]["user"]["login"]
    http = GraphQL::Client::HTTP.new("https://api.github.com/graphql")do
      attr_writer :token

      def headers(_context)
         { Token: @token  }
      end
    end
    http.token = JSON.parse(AuthenticateService.perform(payload["installation"]["id"]))["token"]

    client = GraphQL::Client.new(schema: "db/schema.json", execute: http)
    result = client.query(client.parse(<<-QUERY))
         query {
           repository(owner: "#{repository_owner}", name: "#{payload["repository"]["name"]}")
                 mentionableUsers(last: 10) {
                   nodes{
                         login
                       }
                     }
                   }
               }
             }
    QUERY

    members = result["data"]["repository"]["mentionableUsers"]["nodes"].map{ |node|node["login"] }
    members.delete(pr_owner)

    variables = {"r":
      {
        "pullRequestId": payload["pull_request"]["id"],
        "userIds": [mambers.sample]
      }
    }
    client.query(client.parse(<<-MUTATION, variables))
      mutation RequestReview($r: RequestReviewsInput!) {
        requestReviews(input: $r) {
          pullRequest {
            id
          }
          requestedReviewersEdge {
            node {
              login
            }
          }
        }
      }
    MUTATION
  end
end
