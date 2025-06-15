module SparqlClient

include("Sparql_logger.jl")
include("Sparql_Templates.jl")

using .SparqlLogger
using .SparqlTemplates

using HTTP
using JSON3
using EzXML
using Logging
using Printf


# export API
export SparqlClientSession, Triple, set_query, set_query_type, set_return_format,
       set_query_method, query, query_and_convert,
       parse_rdf_triples, extract_rdf_triples, rdf_query_as_triples,
       set_template_query, bind_variable, expand_query, apply_template,
       save_to_file, save_select_json, save_select_csv,
       save_ask_result, save_rdf_xml, enable_logging, _get_accept_header,
       apply_template, expand_query, bind_variable, set_template_query


# Основные типы

"""
    mutable struct SparqlClientSession

Структура для хранения состояния одной сессии SPARQL-запросов.

# Поля

- `endpoint::String` — URL SPARQL-эндпоинта.
- `query::Union{Nothing, String}` — текст последнего установленного запроса.
- `queryType::Symbol` — тип запроса (`:select`, `:ask`, `:construct`, `:describe`).
- `returnFormat::Symbol` — формат ответа (`:json`, `:xml`, `:rdf`).
- `use_post::Bool` — если `true`, запросы отправляются методом POST, иначе GET.
- `template_query::Union{Nothing, String}` — текст шаблона (если используется).
- `bindings::Dict{String,String}` — параметры для подстановки в шаблон.
"""
mutable struct SparqlClientSession
    endpoint::String
    query::Union{Nothing, String}
    queryType::Symbol
    returnFormat::Symbol
    use_post::Bool
    template_query::Union{Nothing, String}
    bindings::Dict{String, String}
end

"""
    struct Triple

Простая модель RDF-триплета для CONSTRUCT/DESCRIBE-запросов.

# Поля

- `subject::String`
- `predicate::String`
- `object::String`
"""
struct Triple
    subject::String
    predicate::String
    object::String
end


"""
    SparqlClientSession(endpoint::String) → SparqlClientSession

Создаёт и возвращает новую сессию SPARQL-запросов, по умолчанию:
- `queryType = :select`
- `returnFormat = :json`
- `use_post = false`
"""
SparqlClientSession(endpoint::String) = begin
    log_info("Initialized SPARQL session with endpoint: $endpoint")
    SparqlClientSession(endpoint, nothing, :select, :json, false, nothing, Dict())
end


# Установка параметров запроса


"""
    set_query(session::SparqlClientSession, query::String)

Устанавливает SPARQL-запрос `query` в сессии `session`.
"""
function set_query(session::SparqlClientSession, query::String)
    log_info("set_query called. Query set (first 100 chars): $(query[1:min(end,100)])")
    session.query = query
end

"""
    set_query_type(session::SparqlClientSession, qtype::Symbol)

Задает тип запроса `qtype`. Допустимые значения: `:select`, `:ask`, `:construct`, `:describe`.
"""
function set_query_type(session::SparqlClientSession, qtype::Symbol)
    log_info("set_query_type called. Type: $qtype")
    if !(qtype in (:select, :ask, :construct, :describe))
        log_error("Unsupported query type: $qtype")
        error("Unsupported query type.")
    end
    session.queryType = qtype
end

"""
    set_return_format(session::SparqlClientSession, fmt::Symbol)

Задает формат ответа `fmt`. Допустимые: `:json`, `:xml`, `:rdf`.
"""
function set_return_format(session::SparqlClientSession, fmt::Symbol)
    log_info("set_return_format called. Format: $fmt")
    if !(fmt in (:json, :xml, :rdf))
        log_error("Unsupported return format: $fmt")
        error("Unsupported format.")
    end
    session.returnFormat = fmt
end

"""
    set_query_method(session::SparqlClientSession, method::Symbol)

Выбирает HTTP-метод для отправки запросов: `:get` или `:post`.
"""
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


# Выполнение запроса


"""
    query(session::SparqlClientSession; extra_params=Dict()) → Vector{UInt8}

Отправляет HTTP-запрос (GET или POST) к `session.endpoint` с установленным
`session.query` и возвращает «сырое» тело ответа как `Vector{UInt8}`.
Автоматически ставит корректный заголовок `Accept`.
Логирует время выполнения и статус.
"""
function query(session::SparqlClientSession; extra_params::Dict=Dict())
    log_info("query called. Method: $(session.use_post ? "POST" : "GET"), Endpoint: $(session.endpoint)")
    session.query === nothing && (log_error("Query not set."); error("Query not set."))
    headers = Dict("Accept" => _get_accept_header(session.queryType, session.returnFormat))
    log_info("Sending SPARQL query via $(session.use_post ? "POST" : "GET")")
    try
        start_time = time()
        response = session.use_post ? 
            HTTP.post(session.endpoint, headers=headers, body=HTTP.Form(Dict("query"=>session.query) ∪ extra_params)) :
            HTTP.get(session.endpoint, query=Dict("query"=>session.query) ∪ extra_params, headers=headers)
        elapsed = time() - start_time
        log_info(@sprintf("Query completed in %.3f seconds", elapsed))
        response.status != 200 && (log_error("Error $(response.status)"); error("SPARQL endpoint error"))
        log_info("Query successful. Status: $(response.status)")
        return response.body
    catch e
        log_error("HTTP request failed: $e")
        rethrow(e)
    end
end

"""
    _get_accept_header(qtype::Symbol, fmt::Symbol) → String

Формирует и возвращает значение HTTP-заголовка `Accept` для SPARQL-запроса.

# Аргументы
- `qtype::Symbol` — тип SPARQL-запроса (`:select`, `:ask`, `:construct` или `:describe`).
- `fmt::Symbol` — ожидаемый формат ответа (`:json`, `:xml` или `:rdf`).

# Возвращает
- Для `:select` и `:ask`:
  - `"application/sparql-results+json"`, если `fmt == :json`
  - `"application/sparql-results+xml"`, если `fmt == :xml`
- Для `:construct` и `:describe`:
  - `"application/rdf+xml"`
"""
function _get_accept_header(qtype::Symbol, fmt::Symbol)::String
    if qtype in (:select, :ask)
        return fmt == :json ? "application/sparql-results+json" : "application/sparql-results+xml"
    else
        return "application/rdf+xml"
    end
end


"""
    query_and_convert(session::SparqlClientSession; extra_params=Dict()) → Any

Выполняет `query(...)`, парсит ответ в зависимости от `session.queryType`:
- `:ask`  → `Bool`
- `:select` → `Dict` (для JSON) или `EzXML.Document`
- `:construct`/`:describe` → `EzXML.Document`
Логирует общее время «запрос+парсинг».
"""
function query_and_convert(session::SparqlClientSession; extra_params::Dict=Dict())
    log_info("query_and_convert called.")
    start_time = time()
    raw = query(session; extra_params...)
    elapsed = time() - start_time
    log_info(@sprintf("Query+convert in %.3f seconds", elapsed))
    s = String(raw)
    if session.queryType == :ask
        log_info("Parsing ASK response")
        return session.returnFormat == :json ? 
            JSON3.parse(s)["boolean"] :
            lowercase(
                EzXML.nodecontent(
                    EzXML.root(EzXML.parsexml(s))["boolean"]
                )
            ) == "true"
    elseif session.queryType == :select
        log_info("Parsing SELECT response")
        return session.returnFormat == :json ? JSON3.parse(s) : EzXML.parsexml(s)
    elseif session.queryType in (:construct, :describe)
        log_info("Parsing CONSTRUCT/DESCRIBE response")
        return EzXML.parsexml(s)
    else
        log_error("Unsupported type in convert: $(session.queryType)")
        error("Unsupported query type.")
    end
end


# Парсинг RDF/XML ответов


"""
    parse_rdf_triples(xml::EzXML.Document) → Vector{Triple}

Извлекает простой список `Triple(subject,predicate,object)` из CONSTRUCT-ответа.
"""
function parse_rdf_triples(xml::EzXML.Document)::Vector{Triple}
    log_info("parse_rdf_triples called.")
    triples = Triple[]
    for node in EzXML.nodes(EzXML.root(xml))
        EzXML.nodename(node) == "Description" || continue
        subj = get(node, "rdf:about", "(no subject)")
        for child in EzXML.nodes(node)
            EzXML.nodetype(child) != EzXML.ELEMENT_NODE && continue
            pred = EzXML.nodename(child)
            obj = get(child, "rdf:resource", nothing) !== nothing ? child["rdf:resource"] :
                  get(child, "rdf:nodeID", nothing)    !== nothing ? child["rdf:nodeID"] :
                  join(text for text in EzXML.nodes(child) if EzXML.nodetype(text)==EzXML.TEXT_NODE)
            push!(triples, Triple(subj,pred,obj))
        end
    end
    log_info("Parsed $(length(triples)) triples")
    return triples
end

"""
    extract_rdf_triples(xml::EzXML.Document) → Vector{Triple}

Как `parse_rdf_triples`, но для DESCRIBE: возвращает `subject,predicate,object`.
"""
function extract_rdf_triples(xml::EzXML.Document)::Vector{Triple}
    log_info("extract_rdf_triples called.")
    triples = Triple[]
    for node in EzXML.elements(EzXML.root(xml))
        EzXML.nodename(node) == "Description" || continue
        subj = get(node, "rdf:about", "(no subject)")
        for child in EzXML.elements(node)
            pred = EzXML.nodename(child)
            obj = get(child, "rdf:resource", nothing) !== nothing ? child["rdf:resource"] :
                  get(child, "rdf:nodeID", nothing)    !== nothing ? child["rdf:nodeID"] :
                  EzXML.nodecontent(child)
            push!(triples, Triple(subj,pred,obj))
        end
    end
    log_info("Extracted $(length(triples)) triples")
    return triples
end

"""
    rdf_query_as_triples(session::SparqlClientSession) → Vector{Triple}

Выполняет DESCRIBE-запрос и сразу возвращает список `Triple`.
"""
function rdf_query_as_triples(session::SparqlClientSession)::Vector{Triple}
    log_info("rdf_query_as_triples called.")
    doc = query_and_convert(session)
    return extract_rdf_triples(doc)
end


# Сохранение результатов


"""
    save_to_file(path::String, content::AbstractString)

Записывает `content` в файл `path`.
"""
function save_to_file(path::String, content::AbstractString)
    log_info("save_to_file called. Path: $path")
    open(path,"w") do io write(io,content) end
end

"""
    save_select_json(result, path::String; pretty=false)

Сохраняет структуру SELECT-ответа `result` в JSON-файл.
Если `pretty=true`, делает отступы.
"""
function save_select_json(result, path::String; pretty=false)
    log_info("save_select_json called.")
    open(path,"w") do io
        pretty ? JSON3.print(io,result) : JSON3.write(io,result)
    end
end

"""
    save_select_csv(result::AbstractDict, path::String)

Сохраняет SELECT-ответ `result` в CSV с колонками из `head.vars` и 
дополнительно столбцом `lang` (для `xml:lang`).
"""
function save_select_csv(result::AbstractDict, path::String)
    log_info("save_select_csv called.")
    vars = result["head"]["vars"]; rows = result["results"]["bindings"]
    open(path,"w") do io
        println(io, join(vcat(vars,["lang"]),","))
        for row in rows
            vals = String[]; lang=""
            for v in vars
                d = get(row,v,nothing)
                push!(vals, d isa AbstractDict ? get(d,"value","") : "")
                d isa AbstractDict && (lang = get(d,"xml:lang",""))
            end
            println(io, join(vcat(vals,[lang]),","))
        end
    end
end

"""
    save_ask_result(result::Bool, path::String)

Сохраняет результат ASK-запроса (`Yes` или `No`) в текстовый файл.
"""
function save_ask_result(result::Bool, path::String)
    log_info("save_ask_result called.")
    save_to_file(path, result ? "Yes" : "No")
end

"""
    save_rdf_xml(xml::EzXML.Document, path::String)

Сохраняет `xml` (RDF/XML) в файл `path`.
"""
function save_rdf_xml(xml::EzXML.Document, path::String)
    log_info("save_rdf_xml called.")
    save_to_file(path, sprint(print,xml))
end

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

end # module SparqlClient
