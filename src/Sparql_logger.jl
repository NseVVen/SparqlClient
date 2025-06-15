module SparqlLogger

export log_info, log_warn, log_error, enable_logging, init_logger

using Dates

# Путь и дескриптор файла
const log_path_ref = Ref{String}("")
const log_file_ref = Ref{IO}(stdout)

# Два отдельных флага: писать в файл и/или в консоль
const _console_on = Ref(false)
const _file_on    = Ref(false)

"""
    init_logger(query_type::String)

Открывает новый лог-файл `sparql_log_<query_type>_<timestamp>.log`
и включает логирование в файл.
"""
function init_logger(query_type::String)
    ts = Dates.format(now(), "yyyy-mm-dd_HHMMSS")
    log_path_ref[] = "sparql_log_$(query_type)_$(ts).log"
    # открываем файл (старый, если был — перезапишется)
    log_file_ref[] = open(log_path_ref[], "w")
    _file_on[] = true
    log_info("Logging initialized in file $(log_path_ref[])")
end

"""
    enable_logging()

Включает логирование в stdout.
"""
function enable_logging()
    _console_on[] = true
    log_info("Logging enabled (stdout).")
end

"""
    log_info(msg::String)
    log_warn(msg::String)
    log_error(msg::String)

Основная функция логирования: выводит сообщения уровня `level` и
`msg` в файл, если `_file_on[]==true`, и/или в консоль, если `_console_on[]==true`.
"""
function log_msg(level::String, msg::String)
    timestamp = Dates.now()
    line = "[$(timestamp)][$level] $msg"
    if _console_on[]
        println(stdout, line)
        flush(stdout)
    end
    if _file_on[]
        println(log_file_ref[], line)
        flush(log_file_ref[])
    end
end

log_info(msg)  = log_msg("INFO",  msg)
log_warn(msg)  = log_msg("WARN",  msg)
log_error(msg) = log_msg("ERROR", msg)

end # module SparqlLogger
