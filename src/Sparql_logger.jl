module SparqlLogger

# Exported public functions
export log_info, log_warn, log_error, enable_logging, init_logger

using Dates  # Import date and time utilities

# A dynamically assigned path to the log file
const log_path_ref = Ref("")

# A reference to the active log file IO stream (defaults to stdout)
const log_file_ref = Ref{IO}(stdout)

# Generic function to log a message with timestamp and log level
function log_msg(level::String, msg::String)
    timestamp = string(Dates.now())  # Current date-time string
    println(log_file_ref[], "[$timestamp] [$level] $msg")  # Write to log
    flush(log_file_ref[])  # Ensure it is written immediately
end

# Convenience aliases for logging with predefined log levels
log_info(msg) = log_msg("INFO", msg)
log_warn(msg) = log_msg("WARN", msg)
log_error(msg) = log_msg("ERROR", msg)

"""
    init_logger(query_type::String)

Initializes the logger and opens a log file with a timestamped filename:
e.g., `sparql_log_select_2025-05-31_103045.log`
"""
function init_logger(query_type::String)
    timestamp = Dates.format(now(), "yyyy-mm-dd_HHMMSS")  # Timestamp for filename
    log_path_ref[] = "sparql_log_$(query_type)_$(timestamp).log"  # File path
    log_file_ref[] = open(log_path_ref[], "w")  # Open file for writing
    log_info("Logging initialized in $(log_path_ref[])")
end

"""
    enable_logging()

Logs a simple info message to indicate that logging is enabled.
Useful for compatibility and for initializing default behavior.
"""
function enable_logging()
    log_info("Logging enabled.")
end

end 
