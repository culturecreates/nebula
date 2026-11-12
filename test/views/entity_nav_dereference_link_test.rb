require "test_helper"

class EntityNavDereferenceLinkTest < ActionView::TestCase
  # Dereferencing an external URI requires a login, so anonymous visitors
  # (and crawlers) shouldn't be offered the link.
  def render_nav(signed_in:)
    @entity = Entity.new(entity_uri: "https://example.org/event/1", graph: RDF::Graph.new)
    view.define_singleton_method(:user_signed_in?) { signed_in }
    view.define_singleton_method(:user_has_access?) { |_feature| false }
    view.define_singleton_method(:graphdb_link) { |uri| "http://graphdb.example/#{uri}" }
    view.assign(entity: @entity)
    render partial: "entity/entity_nav"
  end

  test "dereference link is shown to signed-in users for external URIs" do
    render_nav(signed_in: true)
    assert_select "a[href^='/dereference/external']"
    assert_select "a[href='https://example.org/event/1']"
    assert_select "a#graphdb"
  end

  # Turbo prefetches links on hover; these fetch the external page, so a
  # hover on the way to another link would crawl the site.
  test "links that dereference the external page opt out of Turbo prefetch" do
    @entity = Entity.new(entity_uri: "https://example.org/event/1", graph: RDF::Graph.new)
    view.define_singleton_method(:user_signed_in?) { true }
    view.define_singleton_method(:user_has_access?) { |feature| feature == "cms_links" }
    view.define_singleton_method(:graphdb_link) { |uri| "http://graphdb.example/#{uri}" }
    view.assign(entity: @entity)
    render partial: "entity/entity_nav"
    assert_select "a[href^='/dereference/external'][data-turbo-prefetch='false']", count: 1
    assert_select "a[href^='/footlight'][data-turbo-prefetch='false']", count: 2
  end

  test "Artsdata entities also hide the GraphDB link from anonymous users" do
    @entity = Entity.new(entity_uri: "http://kg.artsdata.ca/resource/K1-1", graph: RDF::Graph.new)
    view.define_singleton_method(:user_signed_in?) { false }
    view.define_singleton_method(:user_has_access?) { |_feature| false }
    view.define_singleton_method(:graphdb_link) { |uri| "http://graphdb.example/#{uri}" }
    view.assign(entity: @entity)
    render partial: "entity/entity_nav"
    assert_select "a#graphdb", count: 0
    assert_no_match(/\|/, Nokogiri::HTML.fragment(rendered).at_css("div.alternate-name").text, "no trailing bar after Download")
  end

  test "Artsdata entities show the GraphDB link to signed-in users" do
    @entity = Entity.new(entity_uri: "http://kg.artsdata.ca/resource/K1-1", graph: RDF::Graph.new)
    view.define_singleton_method(:user_signed_in?) { true }
    view.define_singleton_method(:user_has_access?) { |_feature| false }
    view.define_singleton_method(:graphdb_link) { |uri| "http://graphdb.example/#{uri}" }
    view.assign(entity: @entity)
    render partial: "entity/entity_nav"
    assert_select "a#graphdb"
  end

  test "dereference link is hidden from anonymous users" do
    render_nav(signed_in: false)
    assert_select "a[href^='/dereference/external']", count: 0
    assert_select "a[href='https://example.org/event/1']", count: 0 # Visit
    assert_select "a#graphdb", count: 0
  end

  def render_artsdata_nav(signed_in:, delete_access:)
    @entity = Entity.new(entity_uri: "http://kg.artsdata.ca/resource/K1-1", graph: RDF::Graph.new)
    view.define_singleton_method(:user_signed_in?) { signed_in }
    view.define_singleton_method(:user_has_access?) { |feature| delete_access && feature == "delete_entity" }
    view.define_singleton_method(:graphdb_link) { |uri| "http://graphdb.example/#{uri}" }
    view.assign(entity: @entity)
    render partial: "entity/entity_nav"
  end

  test "Delete is shown to signed-in users with delete_entity access" do
    render_artsdata_nav(signed_in: true, delete_access: true)
    assert_select "form[action=?]", "/entity", count: 1
  end

  test "Delete is hidden from signed-in users without delete_entity access" do
    render_artsdata_nav(signed_in: true, delete_access: false)
    assert_select "form[action=?]", "/entity", count: 0
    assert_select "a#graphdb"
  end

  test "Delete is hidden from anonymous users" do
    render_artsdata_nav(signed_in: false, delete_access: true)
    assert_select "form[action=?]", "/entity", count: 0
  end
end
