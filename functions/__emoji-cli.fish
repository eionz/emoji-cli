function __emoji-cli_available
  for cmd in $argv
    if which (string match -r '^[\S]+' "$cmd") >/dev/null;
      echo $cmd
      break
    end
  end
end

function __emoji-cli -d 'Emoji completion on the command line'
  set -q EMOJI_CLI_FILTER; or set -l EMOJI_CLI_FILTER 'fzy' 'fzf' 'peco' 'percol'
  set -l buf (commandline -t)
  set -l cursor (commandline -C)
  set -l lbuf (commandline -tc)
  set -l rbuf (string sub --start=(math (string length -- $lbuf) +1) $buf)

  set -l query ''
  set -l mode 'insert'
  if test -n $lbuf
    set -l lquery (string match -r ':?[a-z0-9\+\-\_]+$' -- $lbuf)
    set lbuf (string sub --length=(math (string length -- $lbuf) - (string length -- $lquery; or echo 0)) -- $lbuf)
    set -l rquery (string match -r '^[a-z0-9\+\-\_]+:?' -- $rbuf)
    set rbuf (string sub --start=(math (string length -- $rquery; or echo 0) +1) -- $rbuf)
    set query "$lquery$rquery"

    if string length -q -- $rquery
      set mode 'replace'
    end
  end

  set -l matchq '.+? ?[^:]'
  if test (string match -r "^:.+?" $query)
    set matchq ':.+:'
  end
    # | string match -r '.+? ' \
  cat (dirname (realpath (status -f)))/../emoji.tsv \
    | awk '{ print $2" :"$1":"}' \
    | eval (__emoji-cli_available $EMOJI_CLI_FILTER)" --query '$query'" \
    | string match -r "$matchq" \
    | read -l emoji
  
  if test -n $emoji
    set nbuf "$lbuf$emoji$rbuf"
    if test $mode = 'insert'
      set cursor (math $cursor + (string length -- $nbuf) - (string length -- $buf))
    end
    commandline -rt $nbuf
    commandline -C $cursor
  end
  commandline -f repaint
end
