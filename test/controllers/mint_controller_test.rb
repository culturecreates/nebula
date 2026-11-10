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
    stub_wikidata_label_query
    stub_wikidata_broad_type_query("Q43229")

    get mint_wikidata_url, params: { uri: "Q215380", type: "Q215380" }

    assert_response :success
    assert_includes response.body, "schema:Organization"
  end

  test "wikidata mint preselects the tab type and points out a different Wikidata type" do
    stub_wikidata_label_query
    stub_wikidata_broad_type_query("Q43229")

    # user started on the Person tab (tab_type=Q5) but edited the type field
    # to a subtype ("Q215380", musical group) that resolves to Organization
    get mint_wikidata_url, params: { uri: "Q215380", type: "Q215380", tab_type: "Q5" }

    assert_response :success
    assert_select "select[name=classToMint] option[selected]", text: "schema:Person"
    assert_select ".alert-warning", text: /schema:Organization/
    assert_select "turbo-frame#card-validation"
    assert_select "[data-artsdata-classtomint-value=?]", "schema:Person"
  end

  test "wikidata mint of a cultural centre from the Place tab uses schema:Place, not its Organization superclass" do
    stub_wikidata_label_query
    stub_wikidata_broad_type_query("Q43229") # cultural center (Q1329623) is a subclass of organization

    get mint_wikidata_url, params: { uri: "Q20435679", type: "Q1329623", tab_type: "Q17350442" }

    assert_response :success
    assert_select "select[name=classToMint] option[selected]", text: "schema:Place"
    assert_select "turbo-frame#recon_results[src*=?]", "type=schema%3APlace"
    assert_select "[data-artsdata-classtomint-value=?]", "schema:Place"
  end

  test "the Artsdata type dropdown offers Organization, Place and Person and keeps the selected entity" do
    stub_wikidata_label_query

    get mint_wikidata_url, params: { uri: "Q42", type: "Q5", tab_type: "Q5", label: "Candidate", description: "desc" }

    assert_response :success
    assert_select "select[name=classToMint] option", 3
    %w[schema:Organization schema:Place schema:Person].each do |type|
      assert_select "select[name=classToMint] option[value=?]", type
    end
    assert_select "form:has(select[name=classToMint])" do
      assert_select "input[type=hidden][name=uri][value=Q42]"
      assert_select "input[type=hidden][name=type][value=Q5]"
      assert_select "input[type=hidden][name=tab_type][value=Q5]"
      assert_select "input[type=hidden][name=label][value=Candidate]"
      assert_select "input[type=hidden][name=description][value=desc]"
    end
  end

  test "wikidata mint uses the Artsdata type the user chose in the dropdown" do
    stub_wikidata_label_query
    stub_wikidata_broad_type_query("Q43229")

    get mint_wikidata_url, params: { uri: "Q20435679", type: "Q1329623", tab_type: "Q43229", classToMint: "schema:Place" }

    assert_response :success
    assert_select "select[name=classToMint] option[selected]", text: "schema:Place"
    assert_select ".alert-warning", false
    assert_select "turbo-frame#recon_results[src*=?]", "type=schema%3APlace"
    assert_select "[data-artsdata-classtomint-value=?]", "schema:Place"
    assert_not_requested(:get, WIKIDATA_API, query: hash_including("props" => "claims"))
  end

  test "wikidata mint ignores a classToMint that is not an Artsdata type" do
    stub_wikidata_label_query

    get mint_wikidata_url, params: { uri: "Q42", type: "Q5", tab_type: "Q5", classToMint: "schema:Event" }

    assert_response :success
    assert_select "select[name=classToMint] option[selected]", text: "schema:Person"
  end

  test "wikidata mint asks for an Artsdata type when none can be determined" do
    stub_wikidata_label_query
    stub_wikidata_parents(Hash.new([]))

    get mint_wikidata_url, params: { uri: "Q1", type: "Q123" }

    assert_response :success
    assert_select "select[name=classToMint] option[value='']", text: "Choose a type"
    assert_select "turbo-frame#card-validation", false
    assert_not_includes response.body, "Step 2"
  end

  test "wikidata search tabs follow the chosen Artsdata type" do
    stub_wikidata_label_query

    get mint_wikidata_url, params: { uri: "Q20435679", type: "Q1329623", tab_type: "Q43229", classToMint: "schema:Place" }

    assert_response :success
    assert_select "input#place[checked]"
    assert_select "input#organization[checked]", false
    assert_select "input[name=type][value=Q1329623]"
  end

  test "wikidata mint proceeds directly once the user confirms classToMint" do
    stub_wikidata_label_query

    get mint_wikidata_url, params: { uri: "Q215380", type: "Q215380", tab_type: "Q5", classToMint: "schema:Organization" }

    assert_response :success
    assert_select "turbo-frame#card-validation"
  end

  test "wikidata mint does not ask when the type field matches the tab" do
    stub_wikidata_label_query

    get mint_wikidata_url, params: { uri: "Q42", type: "Q5", tab_type: "Q5" }

    assert_response :success
    assert_select "turbo-frame#card-validation"
  end

  test "wikidata mint falls back to the tab class when the subclass lookup times out" do
    stub_wikidata_label_query
    stub_request(:get, WIKIDATA_API).with(query: hash_including("props" => "claims")).to_timeout

    get mint_wikidata_url, params: { uri: "Q1329623", type: "Q1329623", tab_type: "Q17350442" }

    assert_response :success
    assert_includes response.body, "schema:Place"
  end

  test "wikidata mint uses the label from Wikidata to reconcile with Artsdata" do
    stub_wikidata_label_query

    get mint_wikidata_url, params: { uri: "Q42", label: "Old candidate name", type: "Q5", tab_type: "Q5" }

    assert_response :success
    assert_select "input[name=query][value=?]", "The Beatles"
    assert_select "[data-artsdata-label-value=?]", "The Beatles"
  end

  test "wikidata mint sends a descriptive User-Agent to Wikidata" do
    stub_wikidata_label_query

    get mint_wikidata_url, params: { uri: "Q42", type: "Q5", tab_type: "Q5" }

    assert_requested(:get, WIKIDATA_API, query: hash_including({}),
                     headers: { "User-Agent" => /ArtsdataNebula/ })
  end

  test "wikidata mint falls back to the candidate's name when the label lookup fails" do
    stub_request(:get, WIKIDATA_API).with(query: hash_including({})).to_timeout

    get mint_wikidata_url, params: { uri: "Q134552151", label: "Jazz Festivals Canada",
                                     description: "arts service organization", type: "Q43229", tab_type: "Q43229" }

    assert_response :success
    assert_select "input[name=query][value=?]", "Jazz Festivals Canada"
    assert_select "[data-artsdata-label-value=?]", "Jazz Festivals Canada"
    assert_includes response.body, "arts service organization"
    assert_includes response.body, "query=Jazz+Festivals+Canada"
    assert_not_includes response.body, "query=Q134552151"
  end

  test "wikidata mint never uses the QID as the name and disables minting when no label is available" do
    stub_request(:get, WIKIDATA_API).with(query: hash_including({})).to_timeout

    get mint_wikidata_url, params: { uri: "Q134552151", type: "Q43229", tab_type: "Q43229" }

    assert_response :success
    assert_select "input[name=query][value=?]", "Q134552151", false
    assert_select "[data-controller=artsdata]", false
    assert_includes response.body, "could not be loaded from Wikidata"
  end

  test "reconciliation candidates link to the mint page with their name and description" do
    stub_request(:get, %r{\Ahttps://wikidata.reconci.link/en/api}).to_return(
      status: 200, headers: { "Content-Type" => "application/json" },
      body: { q0: { result: [{ id: "Q134552151", name: "Jazz Festivals Canada", description: "arts service organization",
                               type: [{ id: "Q43229", name: "organization" }], match: true }] } }.to_json
    )

    get reconcile_query_url, params: { reconEndpoint: "https://wikidata.reconci.link/en/api", routeName: "mint_wikidata_path",
                                       query: "Jazz Festivals Canada", type: "Q43229", tabType: "Q43229" }

    assert_response :success
    assert_select "a[href*=?]", "label=Jazz+Festivals+Canada"
    assert_select "a[href*=?]", "description=arts+service+organization"
  end

  test "wikidata mint walks up multiple subclass levels to find the broad type" do
    stub_wikidata_label_query
    stub_wikidata_parents("Q1329623" => ["Q999"], "Q999" => ["Q43229"])

    get mint_wikidata_url, params: { uri: "Q1329623", type: "Q1329623" }

    assert_response :success
    assert_includes response.body, "schema:Organization"
  end

  private

  WIKIDATA_API = "https://www.wikidata.org/w/api.php".freeze

  def stub_wikidata_label_query
    stub_request(:get, WIKIDATA_API)
      .with(query: hash_including("props" => "labels|descriptions"))
      .to_return do |request|
        entities = requested_wikidata_ids(request).to_h do |id|
          [id, { "labels" => { "en" => { "language" => "en", "value" => "The Beatles" } },
                 "descriptions" => { "en" => { "language" => "en", "value" => "band" } } }]
        end
        wikidata_json(entities)
      end
  end

  # Every requested type is a direct subclass of the given broad type.
  def stub_wikidata_broad_type_query(broad_qid)
    stubs = Hash.new([broad_qid])
    stub_wikidata_parents(stubs)
  end

  def stub_wikidata_parents(parents_by_id)
    stub_request(:get, WIKIDATA_API)
      .with(query: hash_including("props" => "claims"))
      .to_return do |request|
        entities = requested_wikidata_ids(request).to_h do |id|
          claims = parents_by_id[id].map { |q| { "mainsnak" => { "datavalue" => { "value" => { "id" => q } } } } }
          [id, { "claims" => { "P279" => claims } }]
        end
        wikidata_json(entities)
      end
  end

  def requested_wikidata_ids(request)
    Rack::Utils.parse_query(URI(request.uri).query)["ids"].split("|")
  end

  def wikidata_json(entities)
    { status: 200, headers: { "Content-Type" => "application/json" }, body: { entities: entities }.to_json }
  end
end
