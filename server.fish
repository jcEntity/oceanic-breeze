#!/usr/bin/env fish

mkfifo data_pipe

function clean_exit --on-signal INT --on-signal TERM
  rm -f data_pipe
  # exit is needed so it actually quits
  exit 0
end

function request_handler
  set -l request_line ""
  set -l requested_path ""

  while read -l line
    set line (string trim -r -c \r -- $line)

    if test -z "$request_line" #we only want the first line
      set request_line $line
    end

    if test -z "$line" #end of request
      break
    end
  end

  set -l method (awk '{print $1}' $request_line)
  set -l path (awk '{print $2}' $request_line)

  if [ method = "GET" ]
    # response headers; we have to use CRLF apparently because of RFC 2616
    printf "HTTP/1.1 200 OK\r\n"
    printf "Content-Type: text/plain\r\n"
    printf "Connection: close\r\n"
    printf "\r\n"

    # response body
    printf "You tried to GET %s\n" "$path"
  else
    # catchall - 405 Method Not Allowed
    printf "HTTP/1.1 405 Method Not Allowed\r\n"
    printf "Allow: GET\r\n"
    printf "Connection: close\r\n"
    printf "\r\n"
  end
end

while true
  nc -l 8080 < data_pipe | request_handler > data_pipe
end
