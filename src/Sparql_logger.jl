module SparqlLogger

export log_info, log_warn, log_error, enable_logging, init_logger

using Dates

const log_path_ref = Ref("")
const log_file_ref = Ref{IO}(stdout)
const LOGGING_ENABLED = Ref(false)

"""
    init_logger(query_type::String)

Открывает новый лог-файл `sparql_log_<query_type>_<timestamp>.log`
и включает логирование.
"""
function init_logger(query_type::String)
    ts = Dates.format(now(),"yyyy-mm-dd_HHMMSS")
    log_path_ref[] = "sparql_log_$(query_type)_$(ts).log"
    log_file_ref[] = open(log_path_ref[],"w")
    LOGGING_ENABLED[] = true
    log_info("Logging initialized in $(log_path_ref[])")
end

"""
    enable_logging()

Включает логирование в stdout.
"""
function enable_logging()
    log_file_ref[] = stdout
    LOGGING_ENABLED[] = true
    log_info("Logging enabled (stdout).")
end

"""
    log_info(msg::String)
    log_warn(msg::String)
    log_error(msg::String)

Выводят в лог соответствующее сообщение, если логирование включено.
"""
function log_msg(level::String, msg::String)
    LOGGING_ENABLED[] || return
    println(log_file_ref[], "[$(Dates.now())][$level] $msg")
    flush(log_file_ref[])
end

log_info(msg) = log_msg("INFO", msg)
log_warn(msg) = log_msg("WARN", msg)
log_error(msg) = log_msg("ERROR", msg)

end # module SparqlLogger