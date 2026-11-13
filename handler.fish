set -l static_folder (path resolve ./static/)

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
  if [ $path = "/" ]
    set path "/index.html"
  end

  set -l filepath (path normalize "$static_folder/$path")
  if string match -q -- "$static_folder*" "$filepath"
    # response headers; we have to use CRLF apparently because of RFC 2616
    printf "HTTP/1.1 200 OK\r\n"
    printf "Content-Type: text/html\r\n"
    printf "Connection: close\r\n"
    printf "\r\n"
  else
    printf "HTTP/1.1 403 Forbidden\r\n"
    printf "Connection: close\r\n"
    printf "\r\n"
    return
  end

  # response body
  cat $filepath
else
  # catchall - 405 Method Not Allowed
  printf "HTTP/1.1 405 Method Not Allowed\r\n"
  printf "Allow: GET\r\n"
  printf "Connection: close\r\n"
  printf "\r\n"
end
