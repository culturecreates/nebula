require "test_helper"

class MintControllerTest < ActionDispatch::IntegrationTest
  
  test "should redirect to root with missing externalUri param" do
    get mint_preview_url, params: { classToMint: 'SomeClass' }
    assert_equal 'Missing a required param. Required list: [:externalUri]', flash[:alert]
  end

  test "wikidata form shows default type id" do
    get mint_wikidata_url

    assert_response :success
    assert_includes response.body, 'name="type"'
    assert_includes response.body, 'value="Q5"'
  end

  test "wikidata search uses submitted type id for reconciliation request" do
    get mint_wikidata_url, params: { wikidata_search: "The Beatles", type: "Q215380" }

    assert_response :success
    assert_includes response.body, 'name="type"'
    assert_includes response.body, 'value="Q215380"'
    assert_includes response.body, "type=Q215380"
  end

  test "wikidata mint resolves classToMint for a custom subtype id via Wikidata subclass lookup" do
    # "Q215380" (musical group) is a custom subtype, not one of the 3 broad
    # types (Q5/Q43229/Q17350442) the form's tabs default to.
    stub_request(:get, "https://query.wikidata.org/sparql")
      .with(query: hash_including("query" => /wdt:P279\*/))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/sparql-results+json" },
        body: {
          head: { vars: ["broad"] },
          results: { bindings: [{ "broad" => { "type" => "uri", "value" => "http://www.wikidata.org/entity/Q43229" } }] }
        }.to_json
      )

    stub_request(:get, "https://query.wikidata.org/sparql")
      .with(query: hash_including("query" => /rdfs:label/))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/sparql-results+json" },
        body: {
          head: { vars: ["label"] },
          results: { bindings: [{ "label" => { "type" => "literal", "value" => "The Beatles", "xml:lang" => "en" } }] }
        }.to_json
      )

    get mint_wikidata_url, params: { uri: "Q215380", type: "Q215380" }

    assert_response :success
    assert_includes response.body, "schema:Organization"
  end

  test "wikidata mint asks the user to choose when the resolved type differs from the tab" do
    stub_wikidata_label_query
    stub_request(:get, "https://query.wikidata.org/sparql")
      .with(query: hash_including("query" => /wdt:P279\*/))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/sparql-results+json" },
        body: {
          head: { vars: ["broad"] },
          results: { bindings: [{ "broad" => { "type" => "uri", "value" => "http://www.wikidata.org/entity/Q43229" } }] }
        }.to_json
      )

    # user started on the Person tab (tab_type=Q5) but edited the type field
    # to a subtype ("Q215380", musical group) that resolves to Organization
    get mint_wikidata_url, params: { uri: "Q215380", type: "Q215380", tab_type: "Q5" }

    assert_response :success
    assert_includes response.body, "schema:Organization"
    assert_includes response.body, "schema:Person"
    assert_not_includes response.body, "Step 1"
  end

  test "wikidata mint proceeds directly once the user confirms classToMint" do
    stub_wikidata_label_query

    get mint_wikidata_url, params: { uri: "Q215380", type: "Q215380", tab_type: "Q5", classToMint: "schema:Organization" }

    assert_response :success
    assert_includes response.body, "Step 1"
  end

  test "wikidata mint does not ask when the type field matches the tab" do
    stub_wikidata_label_query

    get mint_wikidata_url, params: { uri: "Q42", type: "Q5", tab_type: "Q5" }

    assert_response :success
    assert_includes response.body, "Step 1"
  end

  private

  def stub_wikidata_label_query
    stub_request(:get, "https://query.wikidata.org/sparql")
      .with(query: hash_including("query" => /rdfs:label/))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/sparql-results+json" },
        body: {
          head: { vars: ["label"] },
          results: { bindings: [{ "label" => { "type" => "literal", "value" => "The Beatles", "xml:lang" => "en" } }] }
        }.to_json
      )
  end

end
