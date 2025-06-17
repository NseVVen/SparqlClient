module SparqlTemplates

export SELECT_LABELS_BY_CLASS,
       ASK_TYPE,
       CONSTRUCT_RESOURCE,
       DESCRIBE_URI,
       SELECT_TYPES_OF_RESOURCE,
       SELECT_PREDICATES_OF_RESOURCE,
       SELECT_OBJECTS_BY_PREDICATE,
       SELECT_SUBJECTS_REFERRING_RESOURCE


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
