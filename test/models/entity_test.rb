require 'test_helper'

class EntityTest < ActiveSupport::TestCase
  def setup
    @entity = Entity.new(entity_uri: "http://kg.artsdata.ca/resource/K23-300")
    VCR.use_cassette('EntityTest setup event entity K23-300', record: :once) do
      @entity.load_graph
   end
  end
 

  test "should load graph and populate attributes" do
    assert_not_nil @entity.graph
    assert_equal "http://kg.artsdata.ca/resource/K23-300", @entity.entity_uri
    assert_equal "http://schema.org/Event", @entity.type.value
    assert_equal "Le dîner de cons", @entity.label.value
  end
end

class EntityResolveSubjectPathTest < ActiveSupport::TestCase
  def setup
    @entity = Entity.new(entity_uri: "http://kg.artsdata.ca/resource/K23-300")
  end

  def resolve(subject, root_subject, path_predicates)
    @entity.send(:resolve_subject_path, subject, root_subject, path_predicates)
  end

  test "returns the subject unchanged and an empty fragment when it's not a blank node" do
    term, where = resolve("<http://kg.artsdata.ca/resource/K23-300>", nil, [])

    assert_equal "<http://kg.artsdata.ca/resource/K23-300>", term
    assert_equal "", where
  end

  test "returns nil when the subject is a blank node and no root/path is given" do
    assert_nil resolve("_:b0", nil, [])
    assert_nil resolve("_:b0", "<http://kg.artsdata.ca/resource/K23-300>", [])
    assert_nil resolve("_:b0", nil, ["<http://schema.org/address>"])
  end

  test "returns nil when the given root subject is itself a blank node" do
    assert_nil resolve("_:b0", "_:root", ["<http://schema.org/address>"])
  end

  test "builds a single join line and variable for a 1-hop path" do
    term, where = resolve("_:b0", "<http://kg.artsdata.ca/resource/K23-300>", ["<http://schema.org/address>"])

    assert_equal "?bnode_path_0", term
    assert_equal "<http://kg.artsdata.ca/resource/K23-300> <http://schema.org/address> ?bnode_path_0 .", where
  end

  test "chains join lines and variables for a 2-hop path" do
    term, where = resolve("_:b1", "<http://kg.artsdata.ca/resource/K23-300>", ["<http://schema.org/address>", "<http://schema.org/geo>"])

    assert_equal "?bnode_path_1", term
    assert_equal "<http://kg.artsdata.ca/resource/K23-300> <http://schema.org/address> ?bnode_path_0 .\n?bnode_path_0 <http://schema.org/geo> ?bnode_path_1 .", where
  end
end
class EntityDereferenceHtmlTest < ActiveSupport::TestCase
  URL = "https://example.org/event/1"

  def stub_page(body, content_type: "text/html")
    stub_request(:any, URL).to_return(status: 200, body: body, headers: { "Content-Type" => content_type })
  end

  def dereference
    graph = nil
    # the RDF readers print parse warnings (e.g. legal doctype) to stderr; keep the test output clean
    capture_io do
      VCR.turned_off do
        entity = Entity.new(entity_uri: URL)
        entity.dereference
        graph = entity.graph
      end
    end
    graph
  end

  test "extracts JSON-LD embedded in an HTML page" do
    stub_page(<<~HTML)
      <html><head><script type="application/ld+json">
        {"@context":"https://schema.org","@id":"#{URL}","@type":"Event","name":"JSON-LD Event"}
      </script></head><body></body></html>
    HTML

    graph = dereference
    assert_includes graph.query([RDF::URI(URL), RDF::Vocab::SCHEMA.name, nil]).objects.map(&:value), "JSON-LD Event"
  end

  test "does not duplicate nested JSON-LD nodes" do
    stub_page(<<~HTML)
      <html><head><script type="application/ld+json">
        {"@context":"https://schema.org","@id":"#{URL}","@type":"Event","name":"E",
         "location":{"@type":"Place","name":"Venue"}}
      </script></head><body></body></html>
    HTML

    graph = dereference
    assert_equal 1, graph.query([RDF::URI(URL), RDF::Vocab::SCHEMA.location, nil]).count
  end

  test "extracts microdata embedded in an HTML page" do
    stub_page(<<~HTML)
      <html><body itemscope itemtype="https://schema.org/Event" itemid="#{URL}">
        <span itemprop="name">Microdata Event</span>
      </body></html>
    HTML

    graph = dereference
    assert_includes graph.objects.map(&:to_s), "Microdata Event"
  end

  test "extracts RDFa embedded in an HTML page" do
    stub_page(<<~HTML)
      <html><body vocab="https://schema.org/" typeof="Event" resource="#{URL}">
        <span property="name">RDFa Event</span>
      </body></html>
    HTML

    graph = dereference
    assert_includes graph.objects.map(&:to_s), "RDFa Event"
  end

  test "raises when an HTML page has no structured data" do
    stub_page("<html><body><p>Nothing here</p></body></html>")

    error = assert_raises(StandardError) { dereference }
    assert_match(/Could not detect structured data/, error.message)
  end
end

class EntityDisambiguatingDescriptionTest < ActiveSupport::TestCase
  URI = "http://example.org/e".freeze
  PRED = RDF::URI("http://schema.org/disambiguatingDescription")

  def entity_with(*literals)
    graph = RDF::Graph.new
    literals.each { |l| graph << [RDF::URI(URI), PRED, l] }
    Entity.new(entity_uri: URI, graph: graph)
  end

  test "returns nil when absent" do
    assert_nil entity_with.disambiguating_description
  end

  test "prefers the UI locale, then English, then any" do
    fr = RDF::Literal("Chanteur", language: :fr)
    en = RDF::Literal("Singer", language: :en)
    de = RDF::Literal("Sänger", language: :de)
    I18n.with_locale(:en) do
      assert_equal "Singer", entity_with(fr, en).disambiguating_description.value
      assert_equal "Sänger", entity_with(de).disambiguating_description.value
    end
    I18n.with_locale(:fr) do
      assert_equal "Chanteur", entity_with(fr, en).disambiguating_description.value
    end
  end
end
