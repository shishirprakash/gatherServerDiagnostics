for pid in `ps -ef | grep -w "gatherServerDiagnostics.sh daemon" | grep -v -w -e grep | tr -s '  ' ' ' | cut -f 2 -d " "`; do
  echo Killing process tree for `ps -f --pid $pid | sed 1d`
  for p in `pstree -p $pid | tr -s '(' '\n' | grep ")" | cut -f 1 -d ")"`; do
    kill -9 $p > /dev/null 2>&1
  done
done
if [ `ps -ef | grep -w "gatherServerDiagnostics.sh daemon" | grep -v -w -e grep | wc -l` -eq 0 ]; then
  echo Stopped server diagnostics
else
  echo ERROR: Failed to stop server diagnostics!
  ps -ef | grep -w "gatherServerDiagnostics.sh daemon" | grep -v -w -e grep
fi
