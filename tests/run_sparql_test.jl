using SparqlClient

# Function to perform a SELECT query
function run_select()
    log_info("Running SELECT query")
    session = SparqlClientSession("https://dbpedia.org/sparql")  # Initialize session
    set_query(session, """
    SELECT ?label WHERE {
      <http://dbpedia.org/resource/Asturias> rdfs:label ?label
    } LIMIT 5
    """)
    set_query_type(session, :select)  # Specify query type
    set_return_format(session, :xml)  # Choose XML format
    result = query_and_convert(session)  # Execute query
    println("\nSELECT Result:")
    println(result)  # Print XML result
end

# Function to perform an ASK query
function run_ask()
    log_info("Running ASK query")
    session = SparqlClientSession("https://dbpedia.org/sparql")
    set_query(session, """
    ASK {
      <http://dbpedia.org/resource/Asturias> a dbo:Place
    }
    """)
    set_query_type(session, :ask)  
    set_return_format(session, :json)  # Use JSON format
    result = query_and_convert(session)
    println("\nASK Result: ", result ? "Yes" : "No")  # Output as Yes/No
end

# Function to perform a CONSTRUCT query and print triples
function run_construct()
    log_info("Running CONSTRUCT query")
    session = SparqlClientSession("https://dbpedia.org/sparql")
    set_query(session, """
    CONSTRUCT {
      <http://dbpedia.org/resource/Asturias> ?p ?o
    } WHERE {
      <http://dbpedia.org/resource/Asturias> ?p ?o
    } LIMIT 5
    """)
    set_query_type(session, :construct)
    set_return_format(session, :xml)
    doc = query_and_convert(session)
    triples = parse_rdf_triples(doc)  # Extract triples from RDF/XML
    println("\nCONSTRUCT Triples:")
    for t in triples
        println("Predicate: $(t.predicate) → Object: $(t.object)")
    end
end

# Function to perform a DESCRIBE query and print triples
function run_describe()
    log_info("Running DESCRIBE query")
    session = SparqlClientSession("https://dbpedia.org/sparql")
    set_query(session, "DESCRIBE <http://dbpedia.org/resource/Asturias>")
    set_query_type(session, :describe)
    set_return_format(session, :rdf)
    triples = rdf_query_as_triples(session)  # Parse RDF response into triples
    println("\nDESCRIBE Triples:")
    for t in triples
        println("Subject: $(t.subject)")
        println("Predicate: $(t.predicate)")
        println("Object: $(t.object)\n")
    end
end

# Main menu-driven function
function main()
    println("SPARQL Query Tester")
    println("===================")
    println("Choose query type:")
    println("1. SELECT")
    println("2. ASK")
    println("3. CONSTRUCT")
    println("4. DESCRIBE")
    print("Enter number (1-4): ")
    choice = readline()

    # Map input to query type
    query_type = Dict("1" => "select", "2" => "ask", "3" => "construct", "4" => "describe")[choice]

    enable_logging()  # Start logging

    # Call the selected function
    if query_type == "select"
        run_select()
    elseif query_type == "ask"
        run_ask()
    elseif query_type == "construct"
        run_construct()
    elseif query_type == "describe"
        run_describe()
    else
        println("Invalid input. Exiting.")
    end
end

main()
