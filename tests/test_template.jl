# Use imported modules
using SparqlClient

# Enable logging for better traceability
enable_logging()
log_info("=== STARTING TEMPLATE TEST ===")

# Initialize SPARQL session with DBpedia endpoint
session = SparqlClientSession("https://dbpedia.org/sparql")
set_return_format(session, :json)

# -------------------------------------------------------------------
# 1. SELECT_LABELS_BY_CLASS
# Retrieves labels for resources of a given class and language
# -------------------------------------------------------------------
println("\n--- SELECT_LABELS_BY_CLASS ---")
set_template_query(session, SELECT_LABELS_BY_CLASS)
bind_variable(session, "class", "<http://dbpedia.org/ontology/Place>")
bind_variable(session, "lang", "en")
bind_variable(session, "limit", "3")
apply_template(session)
set_query_type(session, :select)
result = query_and_convert(session)
for b in result["results"]["bindings"]
    println("Entity: ", b["entity"]["value"], " → Label: ", b["label"]["value"])
end

# -------------------------------------------------------------------
# 2. ASK_TYPE
# Checks if a resource belongs to a given type
# -------------------------------------------------------------------
println("\n--- ASK_TYPE ---")
set_template_query(session, ASK_TYPE)
bind_variable(session, "resource", "<http://dbpedia.org/resource/Asturias>")
bind_variable(session, "type", "<http://dbpedia.org/ontology/Place>")
apply_template(session)
set_query_type(session, :ask)
ask_result = query_and_convert(session)
println("Is Asturias a Place? ", ask_result ? "Yes" : "No")

# -------------------------------------------------------------------
# 3. SELECT_TYPES_OF_RESOURCE
# Lists all RDF types of the resource
# -------------------------------------------------------------------
println("\n--- SELECT_TYPES_OF_RESOURCE ---")
set_template_query(session, SELECT_TYPES_OF_RESOURCE)
bind_variable(session, "resource", "<http://dbpedia.org/resource/Asturias>")
apply_template(session)
set_query_type(session, :select)
result = query_and_convert(session)
for b in result["results"]["bindings"]
    println("Type: ", b["type"]["value"])
end

# -------------------------------------------------------------------
# 4. SELECT_PREDICATES_OF_RESOURCE
# Lists all unique predicates used with the resource
# -------------------------------------------------------------------
println("\n--- SELECT_PREDICATES_OF_RESOURCE ---")
set_template_query(session, SELECT_PREDICATES_OF_RESOURCE)
bind_variable(session, "resource", "<http://dbpedia.org/resource/Asturias>")
apply_template(session)
set_query_type(session, :select)
result = query_and_convert(session)
for b in result["results"]["bindings"]
    println("Predicate: ", b["p"]["value"])
end

# -------------------------------------------------------------------
# 5. SELECT_OBJECTS_BY_PREDICATE
# Returns distinct objects for a given predicate
# -------------------------------------------------------------------
println("\n--- SELECT_OBJECTS_BY_PREDICATE ---")
set_template_query(session, SELECT_OBJECTS_BY_PREDICATE)
bind_variable(session, "predicate", "<http://dbpedia.org/ontology/birthPlace>")
bind_variable(session, "limit", "5")
apply_template(session)
set_query_type(session, :select)
result = query_and_convert(session)
for b in result["results"]["bindings"]
    println("Object: ", b["o"]["value"])
end

# -------------------------------------------------------------------
# 6. SELECT_SUBJECTS_REFERRING_RESOURCE
# Returns subjects that refer to the given resource
# -------------------------------------------------------------------
println("\n--- SELECT_SUBJECTS_REFERRING_RESOURCE ---")
set_template_query(session, SELECT_SUBJECTS_REFERRING_RESOURCE)
bind_variable(session, "resource", "<http://dbpedia.org/resource/Asturias>")
bind_variable(session, "limit", "5")
apply_template(session)
set_query_type(session, :select)
result = query_and_convert(session)
for b in result["results"]["bindings"]
    println("Subject: ", b["s"]["value"])
end

# -------------------------------------------------------------------
# 7. CONSTRUCT_RESOURCE
# Returns RDF triples (predicate-object) for a given subject
# -------------------------------------------------------------------
println("\n--- CONSTRUCT_RESOURCE ---")
set_template_query(session, CONSTRUCT_RESOURCE)
bind_variable(session, "subject", "<http://dbpedia.org/resource/Asturias>")
bind_variable(session, "limit", "5")
apply_template(session)
set_query_type(session, :construct)
set_return_format(session, :xml)
xml = query_and_convert(session)
triples = parse_rdf_triples(xml)
for t in triples
    println("Predicate: ", t.predicate, " → Object: ", t.object)
end

# -------------------------------------------------------------------
# 8. DESCRIBE_URI
# Provides a full RDF description of the resource
# -------------------------------------------------------------------
println("\n--- DESCRIBE_URI ---")
set_template_query(session, DESCRIBE_URI)
bind_variable(session, "uri", "<http://dbpedia.org/resource/Asturias>")
apply_template(session)
set_query_type(session, :describe)
set_return_format(session, :rdf)
triples = rdf_query_as_triples(session)
for t in triples
    println("Subject: ", t.subject)
    println("Predicate: ", t.predicate)
    println("Object: ", t.object)
    println("---")
end

log_info("=== TEMPLATE TEST COMPLETE ===")
