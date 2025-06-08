using SparqlClient


# Create a new SPARQL session with DBpedia endpoint
session = SparqlClientSession("https://dbpedia.org/sparql")

# Define a SELECT query to retrieve labels of a specific resource
set_query(session, """
SELECT ?label WHERE { 
  <http://dbpedia.org/resource/Asturias> rdfs:label ?label 
} LIMIT 5
""")

# Specify query type and expected result format
set_query_type(session, :select)
set_return_format(session, :json)

# Specify to use HTTP POST method for query submission
set_query_method(session, :post)

# Execute the query
println("SELECT query result:")
result = query_and_convert(session)

# Print the JSON result
println(result)

# Save the result to a JSON file
save_select_json(result, "select_result.json")

# Save the result to a CSV file with language column
save_select_csv(result, "select_result.csv")