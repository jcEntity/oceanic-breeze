#!/usr/bin/env fish

rm -f data_pipe
mkfifo data_pipe

function request_handler
  set -l request_line ""
  set -l requested_path ""

  while read --line line
    set line (string trim -r -c \r -- $line)

    if test -z "$request_line" #we only want the first line
      set request_line $line
    end

    if test -z "$line" #end of request
      break
    end
  end

  if test -z "$request_line"
    printf "HTTP/1.1 400 Bad Request\r\n"
    printf "Connection: close\r\n"
    printf "\r\n"
    return
  end

  set -l request_parts (string split " " -- $request_line)
  set -l method $request_parts[1]
  set -l path $request_parts[2]

  if [ $method = "GET" ]
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
  nc -N -l 8080 < data_pipe | request_handler > data_pipe
end
