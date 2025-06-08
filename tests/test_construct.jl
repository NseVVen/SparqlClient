using SparqlClient

# Enable logging for debugging purposes
enable_logging()

# Create a new session targeting the DBpedia SPARQL endpoint
session = SparqlClientSession("https://dbpedia.org/sparql")

# Define a SPARQL CONSTRUCT query to retrieve triples for a specific resource
set_query(session, """
CONSTRUCT {
  <http://dbpedia.org/resource/Asturias> ?p ?o
} WHERE {
  <http://dbpedia.org/resource/Asturias> ?p ?o
} LIMIT 5
""")

# Set query type and return format (RDF/XML)
set_query_type(session, :construct)
set_return_format(session, :xml)

# Execute the query
xml = query_and_convert(session)

# Parse XML response into a list of triples
triples = parse_rdf_triples(xml)

# Print each triple to the console
println("Parsed CONSTRUCT Triples:")
for t in triples
    println("Predicate: $(t.predicate) => Object: $(t.object)")
end

# Save raw RDF/XML to a file
save_rdf_xml(xml, "construct_result.rdf")
