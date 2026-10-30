require "test_helper"

class EntityLocalContextTest < ActiveSupport::TestCase
  # The context for our own host must come from public/context.jsonld, never from an
  # HTTP request back to the app (which stalls when every Puma thread is busy).
  test "own context.jsonld is resolved from disk without an HTTP request" do
    url = "https://kg.artsdata.ca/context.jsonld"
    returned = EntityController.new.send(:preload_local_context, url)
    assert_equal url, returned

    expanded = nil
    assert_nothing_raised do
      expanded = JSON::LD::API.compact(
        [{ "@id" => "http://kg.artsdata.ca/resource/K1-1", "@type" => ["http://schema.org/Place"],
           "http://schema.org/name" => [{ "@value" => "Test" }] }],
        url
      )
    end
    assert_equal url, expanded["@context"]
    assert_equal "Test", expanded["name"]["@none"] # name is a language map in our context
    assert_not_requested :get, url
  end
end
