using SparqlClient

# Enable logging for debugging and traceability

# Create a new SPARQL client session for the DBpedia endpoint
session = SparqlClientSession("https://dbpedia.org/sparql")

# Set up an ASK query to check if the resource is a dbo:Place
set_query(session, """
ASK {
  <http://dbpedia.org/resource/Asturias> a dbo:Place
}
""")

# Specify query type and desired return format
set_query_type(session, :ask)
set_return_format(session, :json)

# Execute the query
println("ASK query result:")
result = query_and_convert(session)

# Print the boolean result
println(result ? "Yes" : "No")

# Save the result to a text file
save_ask_result(result, "ask_result.txt")
