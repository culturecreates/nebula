require 'test_helper'


class EntityTest < ActiveSupport::TestCase
  def setup
    @entity = Entity.new(entity_uri: "http://kg.artsdata.ca/resource/K23-300")
    VCR.use_cassette('EntityTest setup event entity K23-300') do
      @entity.load_graph
    end
   
  end

  test "no blank nodes" do
    blank_node_count = 0
    @entity.graph.each_statement do |statement|
      blank_node_count += 1 if statement.object.is_a?(RDF::Node)
    end
    assert_equal(0, blank_node_count, "Graph was not expected to have any blank nodes")
  end

  test "convert blank nodes" do
    blank_node = RDF::Node.new
    @entity.graph << RDF::Statement.new(RDF::URI("http://test.com/a"),  RDF::RDFS.seeAlso, blank_node)
    @entity.graph << RDF::Statement.new(blank_node,  RDF::RDFS.label, "Blank node label" )
    blank_node_count = 0
    @entity.graph.each_statement do |statement|
      blank_node_count += 1 if statement.object.is_a?(RDF::Node)
    end
    assert(blank_node_count, "Graph should have atleast one blank node")

    @entity.replace_blank_nodes
    blank_node_count = 0
    @entity.graph.each_statement do |statement|
      blank_node_count += 1 if statement.object.is_a?(RDF::Node)
    end
    assert_equal(0, blank_node_count, "Graph should no longer have blank nodes")
    
  end

  test "convert 2 level blank nodes" do
    blank_node = RDF::Node.new
    blank_node2 = RDF::Node.new
    @entity.graph << RDF::Statement.new(RDF::URI("http://test.com/a"),  RDF::RDFS.seeAlso, blank_node)
    @entity.graph << RDF::Statement.new(blank_node,  RDF::RDFS.seeAlso, blank_node2 )
    @entity.graph << RDF::Statement.new(blank_node2,  RDF::RDFS.label, "Second Level blank node label" )

    blank_node_count = 0
    @entity.graph.each_statement do |statement|
      blank_node_count += 1 if statement.subject.is_a?(RDF::Node) && statement.object.is_a?(RDF::Node)
    end
    assert(blank_node_count, "Graph should have atleast one blank node subject and object in the same triple")

    @entity.replace_blank_nodes
    @entity.replace_blank_nodes
    blank_node_count = 0
    @entity.graph.each_statement do |statement|
      blank_node_count += 1 if statement.subject.is_a?(RDF::Node) || statement.object.is_a?(RDF::Node) 
    end
    assert_equal(0, blank_node_count, "Graph should no longer have blank nodes")
    
  end


  
end