require 'test_helper'

class GithubControllerTest < ActionDispatch::IntegrationTest
  setup do
    @controller = GithubController.new
  end

  test "should get workflows" do
    stub_request(:get, "https://api.github.com/repos/culturecreates/footlight-aggregator/actions/runs?per_page=10")
      .to_return(status: 200, body: { workflow_runs: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    get github_workflows_url
    assert_response :failure
    assert_equal [], controller.instance_variable_get(:@workflows)
  end

end