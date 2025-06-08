module SparqlLogger

export log_info, log_warn, log_error, enable_logging, init_logger

using Dates  # Import date and time utilities

const log_path_ref = Ref("")
const log_file_ref = Ref{IO}(stdout)

# Флаг: разрешено ли логирование
const LOGGING_ENABLED = Ref(false)

function log_msg(level::String, msg::String)
    if !LOGGING_ENABLED[]
        return  # Логирование выключено
    end
    timestamp = string(Dates.now())
    println(log_file_ref[], "[$timestamp] [$level] $msg")
    flush(log_file_ref[])
end

log_info(msg) = log_msg("INFO", msg)
log_warn(msg) = log_msg("WARN", msg)
log_error(msg) = log_msg("ERROR", msg)

"""
    init_logger(query_type::String)

Initializes the logger and opens a log file with a timestamped filename:
e.g., `sparql_log_select_2025-05-31_103045.log`
"""
function init_logger(query_type::String)
    timestamp = Dates.format(now(), "yyyy-mm-dd_HHMMSS")
    log_path_ref[] = "sparql_log_$(query_type)_$(timestamp).log"
    log_file_ref[] = open(log_path_ref[], "w")
    LOGGING_ENABLED[] = true
    log_info("Logging initialized in $(log_path_ref[])")
end

"""
    enable_logging()

Explicitly enable logging (same as init_logger but to stdout).
"""
function enable_logging()
    log_file_ref[] = stdout
    LOGGING_ENABLED[] = true
    log_info("Logging enabled (stdout).")
end

end
