kill-port() {
  if [ -z "$1" ]; then
    echo "Usage: kill-port <port>"
    return 1
  fi

  local pid
  pid=$(lsof -i :"$1" -t 2>/dev/null)

  if [ -z "$pid" ]; then
    echo "No process found on port $1"
    return 1
  fi

  kill -9 "$pid" && echo "Killed process $pid on port $1"
}
