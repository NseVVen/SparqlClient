module SparqlTemplates

# Export all available SPARQL query templates
export SELECT_LABELS_BY_CLASS,
       ASK_TYPE,
       CONSTRUCT_RESOURCE,
       DESCRIBE_URI,
       SELECT_TYPES_OF_RESOURCE,
       SELECT_PREDICATES_OF_RESOURCE,
       SELECT_OBJECTS_BY_PREDICATE,
       SELECT_SUBJECTS_REFERRING_RESOURCE,
       set_template_query, bind_variable, 
       expand_query, apply_template 


"""
    set_template_query(session::SparqlClientSession, template::String)

Устанавливает шаблон `template` для последующей подстановки.
"""
function set_template_query(session::SparqlClientSession, template::String)
    log_info("set_template_query called.")
    session.template_query = template
    session.bindings = Dict()
    log_info("Template set.")
end

"""
    bind_variable(session::SparqlClientSession, name::String, value::String)

Привязывает значение `value` к переменной `{{name}}` в шаблоне.
"""
function bind_variable(session::SparqlClientSession, name::String, value::String)
    log_info("bind_variable called for $name → $value")
    session.bindings[name] = value
end

"""
    expand_query(session::SparqlClientSession) → String

Разворачивает текущий `template_query` с учётом всех `bindings`.
"""
function expand_query(session::SparqlClientSession)::String
    log_info("expand_query called.")
    session.template_query === nothing && error("Template not set.")
    q = session.template_query
    for (k,v) in session.bindings
        q = replace(q, "{{$k}}"=>v)
    end
    occursin(r"\{\{.*?\}\}", q) && error("Unresolved variables remain.")
    return q
end

"""
    apply_template(session::SparqlClientSession)

Разворачивает и сразу устанавливает результат как `session.query`.
"""
function apply_template(session::SparqlClientSession)
    log_info("apply_template called.")
    set_query(session, expand_query(session))
end

"""
Returns labels for all resources of the given class.
Parameters:
  - {{class}}  — URI of the class
  - {{lang}}   — preferred label language
  - {{limit}}  — result limit
"""
const SELECT_LABELS_BY_CLASS = """
SELECT ?entity ?label WHERE {
  ?entity a {{class}} ;
          rdfs:label ?label .
  FILTER(lang(?label) = "{{lang}}")
}
LIMIT {{limit}}
"""

"""
Checks if the resource is of the given RDF type.
Parameters:
  - {{resource}} — the resource URI
  - {{type}}     — RDF class/type to check
"""
const ASK_TYPE = """
ASK {
  {{resource}} a {{type}} .
}
"""

"""
Returns all predicate-object pairs for the specified subject.
Parameters:
  - {{subject}} — subject URI
  - {{limit}}   — result limit
"""
const CONSTRUCT_RESOURCE = """
CONSTRUCT {
  {{subject}} ?p ?o .
} WHERE {
  {{subject}} ?p ?o .
}
LIMIT {{limit}}
"""

"""
DESCRIBE query for the specified resource.
Parameters:
  - {{uri}} — URI of the resource to describe
"""
const DESCRIBE_URI = """
DESCRIBE {{uri}}
"""

"""
Retrieves all RDF types (rdf:type) of the resource.
Parameters:
  - {{resource}} — resource URI
"""
const SELECT_TYPES_OF_RESOURCE = """
SELECT ?type WHERE {
  {{resource}} a ?type .
}
"""

"""
Retrieves all predicates associated with the resource.
Parameters:
  - {{resource}} — resource URI
"""
const SELECT_PREDICATES_OF_RESOURCE = """
SELECT DISTINCT ?p WHERE {
  {{resource}} ?p ?o .
}
"""

"""
Retrieves all distinct objects for a given predicate.
Parameters:
  - {{predicate}} — predicate URI
  - {{limit}}     — result limit
"""
const SELECT_OBJECTS_BY_PREDICATE = """
SELECT DISTINCT ?o WHERE {
  ?s {{predicate}} ?o .
}
LIMIT {{limit}}
"""

"""
Finds all subjects that reference the given resource.
Parameters:
  - {{resource}} — resource URI
  - {{limit}}    — result limit
"""
const SELECT_SUBJECTS_REFERRING_RESOURCE = """
SELECT ?s WHERE {
  ?s ?p {{resource}} .
}
LIMIT {{limit}}
"""

end 
