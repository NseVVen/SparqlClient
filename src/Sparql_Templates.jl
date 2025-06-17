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
Возвращает метки для всех ресурсов указанного класса.
Параметры:
  - {{class}}  — URI класса
  - {{lang}}   — предпочитаемый язык меток
  - {{limit}}  — ограничение на число результатов
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
Проверяет, является ли ресурс указанного RDF-типа.
Параметры:
  - {{resource}} — URI ресурса
  - {{type}}     — проверяемый класс/тип RDF
"""
const ASK_TYPE = """
ASK {
  {{resource}} a {{type}} .
}
"""

"""
Возвращает все пары предикат-объект для указанного субъекта.
Параметры:
  - {{subject}} — URI субъекта
  - {{limit}}   — ограничение на число результатов
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
DESCRIBE-запрос для указанного ресурса.
Параметры:
  - {{uri}} — URI описываемого ресурса
"""
const DESCRIBE_URI = """
DESCRIBE {{uri}}
"""

"""
Получает все RDF-типы (rdf:type) ресурса.
Параметры:
  - {{resource}} — URI ресурса
"""
const SELECT_TYPES_OF_RESOURCE = """
SELECT ?type WHERE {
  {{resource}} a ?type .
}
"""

"""
Получает все предикаты, связанные с ресурсом.
Параметры:
  - {{resource}} — URI ресурса
"""
const SELECT_PREDICATES_OF_RESOURCE = """
SELECT DISTINCT ?p WHERE {
  {{resource}} ?p ?o .
}
"""

"""
Получает все уникальные объекты по заданному предикату.
Параметры:
  - {{predicate}} — URI предиката
  - {{limit}}     — ограничение на число результатов
"""
const SELECT_OBJECTS_BY_PREDICATE = """
SELECT DISTINCT ?o WHERE {
  ?s {{predicate}} ?o .
}
LIMIT {{limit}}
"""

"""
Находит все субъекты, которые ссылаются на указанный ресурс.
Параметры:
  - {{resource}} — URI ресурса
  - {{limit}}    — ограничение на число результатов
"""
const SELECT_SUBJECTS_REFERRING_RESOURCE = """
SELECT ?s WHERE {
  ?s ?p {{resource}} .
}
LIMIT {{limit}}
"""

end
