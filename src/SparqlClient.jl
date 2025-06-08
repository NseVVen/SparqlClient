module SparqlClient

include("Sparql_logger.jl")
include("Sparql_Templates.jl")

using .SparqlLogger
using .SparqlTemplates

# Import required libraries
using HTTP
using JSON
using EzXML
using Logging
using Printf

# Define session object to store SPARQL request configuration
mutable struct SparqlClientSession
    endpoint::String
    query::Union{Nothing, String}
    queryType::Symbol
    returnFormat::Symbol
    use_post::Bool
    template_query::Union{Nothing, String}
    bindings::Dict{String, String}
end

# Basic RDF triple (used for CONSTRUCT)
struct Triple
    subject::String
    predicate::String
    object::String
end

# Constructor with default values and log
SparqlClientSession(endpoint::String) = begin
    log_info("Initialized SPARQL session with endpoint: $endpoint")
    SparqlClientSession(endpoint, nothing, :select, :json, false, nothing, Dict())
end

# Set SPARQL query string
function set_query(session::SparqlClientSession, query::String)
    log_info("set_query called. Query set (first 100 chars): $(query[1:min(end, 100)])")
    session.query = query
end

# Set the query type (:select, :ask, :construct, :describe)
function set_query_type(session::SparqlClientSession, qtype::Symbol)
    log_info("set_query_type called. Type: $qtype")
    if !(qtype in [:select, :ask, :construct, :describe])
        log_error("Unsupported query type: $qtype")
        error("Unsupported query type.")
    end
    session.queryType = qtype
end

# Set expected return format (:json, :xml, :rdf)
function set_return_format(session::SparqlClientSession, fmt::Symbol)
    log_info("set_return_format called. Format: $fmt")
    if !(fmt in [:json, :xml, :rdf])
        log_error("Unsupported return format: $fmt")
        error("Unsupported format.")
    end
    session.returnFormat = fmt
end

# Return appropriate HTTP Accept header
function _get_accept_header(qtype::Symbol, fmt::Symbol)::String
    # Это вспомогательная, можно не логировать отдельно
    if qtype in [:select, :ask]
        return fmt == :json ? "application/sparql-results+json" : "application/sparql-results+xml"
    else
        return "application/rdf+xml"
    end
end

# Execute the SPARQL query over HTTP
function query(session::SparqlClientSession; extra_params::Dict=Dict())
    log_info("query called. Method: $(session.use_post ? "POST" : "GET"), Endpoint: $(session.endpoint)")
    if session.query === nothing
        log_error("Query not set before sending.")
        error("Query not set.")
    end

    headers = Dict("Accept" => _get_accept_header(session.queryType, session.returnFormat))
    log_info("Sending SPARQL query via $(session.use_post ? "POST" : "GET") to $(session.endpoint)")

    try
        if session.use_post
            form_data = Dict("query" => session.query)
            merge!(form_data, extra_params)
            response = HTTP.post(session.endpoint, headers=headers, body=HTTP.Form(form_data))
        else
            query_params = Dict("query" => session.query)
            merge!(query_params, extra_params)
            response = HTTP.get(session.endpoint, query=query_params, headers=headers)
        end

        if response.status != 200
            log_error("SPARQL error $(response.status): $(String(response.body))")
            error("SPARQL endpoint returned error")
        end

        log_info("Query successful. Status: $(response.status)")
        return response.body

    catch e
        log_error("HTTP request failed: $(e)")
        rethrow(e)
    end
end

# Set HTTP method for the query
function set_query_method(session::SparqlClientSession, method::Symbol)
    log_info("set_query_method called. Method: $method")
    if method == :post
        session.use_post = true
        log_info("HTTP method set to POST")
    elseif method == :get
        session.use_post = false
        log_info("HTTP method set to GET")
    else
        log_error("Unsupported HTTP method: $method")
        error("Unsupported HTTP method. Use :get or :post.")
    end
end

# Execute query and automatically convert response to usable format
function query_and_convert(session::SparqlClientSession; extra_params::Dict=Dict())
    log_info("query_and_convert called.")
    start_time = time()
    raw_response = query(session; extra_params=extra_params)
    elapsed = time() - start_time
    log_info(@sprintf("Query executed in %.3f seconds", elapsed))

    str_response = String(raw_response)

    try
        if session.queryType == :ask
            log_info("Parsing ASK response")
            return session.returnFormat == :json ?
                JSON.parse(str_response)["boolean"] :
                lowercase(EzXML.text(EzXML.parsexml(str_response)["boolean"])) == "true"
        elseif session.queryType == :select
            log_info("Parsing SELECT response")
            return session.returnFormat == :json ?
                JSON.parse(str_response) :
                EzXML.parsexml(str_response)
        elseif session.queryType in [:construct, :describe]
            log_info("Parsing CONSTRUCT/DESCRIBE response")
            return EzXML.parsexml(str_response)
        else
            log_error("Unsupported query type in query_and_convert: $(session.queryType)")
            error("Unsupported query type: $(session.queryType)")
        end
    catch e
        log_error("Failed to parse response: $(e)")
        rethrow(e)
    end
end

# Parse CONSTRUCT XML into simplified Triple list
function parse_rdf_triples(xml::EzXML.Document)::Vector{Triple}
    log_info("parse_rdf_triples called.")
    triples = Triple[]
    root = EzXML.root(xml)
    for node in EzXML.nodes(root)
        if EzXML.nodename(node) == "Description"
            subject = haskey(node, "rdf:about") ? node["rdf:about"] : "(no subject)"
            for child in EzXML.nodes(node)
                if EzXML.nodetype(child) == EzXML.ELEMENT_NODE
                    predicate = EzXML.nodename(child)
                    object = haskey(child, "rdf:resource") ? child["rdf:resource"] :
                             haskey(child, "rdf:nodeID")    ? child["rdf:nodeID"] :
                             join([n.content for n in EzXML.nodes(child) if EzXML.nodetype(n) == EzXML.TEXT_NODE])
                    push!(triples, Triple(subject, predicate, object))
                end
            end
        end
    end
    log_info("Parsed $(length(triples)) triples from CONSTRUCT.")
    return triples
end

# Extract RDF triples with subjects from RDF/XML
function extract_rdf_triples(xml::EzXML.Document)::Vector{Triple}
    log_info("extract_rdf_triples called.")
    triples = Triple[]
    root = EzXML.root(xml)
    for node in EzXML.elements(root)
        if EzXML.nodename(node) == "Description"
            subject = haskey(node, "rdf:about") ? node["rdf:about"] : "(no subject)"
            for child in EzXML.elements(node)
                predicate = EzXML.nodename(child)
                object = haskey(child, "rdf:resource") ? child["rdf:resource"] :
                         haskey(child, "rdf:nodeID")    ? child["rdf:nodeID"] :
                         EzXML.nodecontent(child)
                push!(triples, Triple(subject, predicate, object))
            end
        end
    end
    log_info("Extracted $(length(triples)) triples from DESCRIBE.")
    return triples
end

# Perform DESCRIBE query and return parsed Triple objects
function rdf_query_as_triples(session::SparqlClientSession)::Vector{Triple}
    log_info("rdf_query_as_triples called.")
    doc = query_and_convert(session)
    return extract_rdf_triples(doc)
end

# Assign a SPARQL query template
function set_template_query(session::SparqlClientSession, template::String)
    log_info("set_template_query called.")
    session.template_query = template
    session.bindings = Dict()
    log_info("Template query set.")
end

# Bind a variable for template substitution
function bind_variable(session::SparqlClientSession, name::String, value::String)
    log_info("bind_variable called for $name with value $(value[1:min(end, 100)]).")
    session.bindings[name] = value
    log_info("Bound variable {{$name}} → $value")
end

# Expand query by applying all bound variables to the template
function expand_query(session::SparqlClientSession)::String
    log_info("expand_query called.")
    if session.template_query === nothing
        error("Template query not set.")
    end

    query = session.template_query
    for (k, v) in session.bindings
        query = replace(query, "{{$k}}" => v)
    end

    if occursin(r"\{\{.*?\}\}", query)
        log_error("Template query contains unresolved variables.")
        error("Template query contains unresolved variables. Use `bind_variable` to provide all values.")
    end

    return query
end

# Generate final query from template and assign it to the session
function apply_template(session::SparqlClientSession)
    log_info("apply_template called.")
    set_query(session, expand_query(session))
end

# Save content to a text file
function save_to_file(path::String, content::AbstractString)
    log_info("save_to_file called. Path: $path")
    open(path, "w") do io
        write(io, content)
    end
    log_info("Saved query result to $path")
end

# Save SELECT result as JSON file
function save_select_json(result::Dict, path::String)
    log_info("save_select_json called. Path: $path")
    save_to_file(path, JSON.json(result))
end

# Save SELECT result as CSV with language column
function save_select_csv(result::Dict, path::String)
    log_info("save_select_csv called. Path: $path")
    vars = result["head"]["vars"]
    rows = result["results"]["bindings"]

    open(path, "w") do io
        extended_vars = vcat(vars, ["lang"])
        println(io, join(extended_vars, ","))

        for row in rows
            values = String[]
            lang_value = ""
            for var in vars
                val_dict = get(row, var, nothing)
                if val_dict isa Dict
                    push!(values, get(val_dict, "value", ""))
                    lang_value = get(val_dict, "xml:lang", "")
                else
                    push!(values, "")
                end
            end
            push!(values, lang_value)
            println(io, join(values, ","))
        end
    end
    log_info("Saved SELECT result as CSV (with language) to $path")
end

# Save ASK result as plain text (Yes/No)
function save_ask_result(result::Bool, path::String)
    log_info("save_ask_result called. Path: $path")
    save_to_file(path, result ? "Yes" : "No")
end

# Save RDF/XML document to file
function save_rdf_xml(xml::EzXML.Document, path::String)
    log_info("save_rdf_xml called. Path: $path")
    rdf_str = sprint(print, xml)  # Serialize XML to string
    save_to_file(path, rdf_str)
end

# Export public API
export SparqlClientSession,
       set_query, set_query_type, set_return_format,
       query, query_and_convert,
       parse_rdf_triples, extract_rdf_triples,
       Triple, rdf_query_as_triples,
       set_query_method, set_template_query, 
       bind_variable, expand_query, apply_template,
       save_to_file, save_select_json, save_select_csv,
       save_ask_result, save_rdf_xml, log_info, 
       log_warn, log_error, enable_logging, init_logger,
       SELECT_LABELS_BY_CLASS,ASK_TYPE, CONSTRUCT_RESOURCE,
       DESCRIBE_URI, SELECT_TYPES_OF_RESOURCE,
       SELECT_PREDICATES_OF_RESOURCE, SELECT_OBJECTS_BY_PREDICATE,
       SELECT_SUBJECTS_REFERRING_RESOURCE

end  
