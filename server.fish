#!/usr/bin/env fish

while true
  nc -l -p 8080 -c -e "fish ./handler.fish"
end
