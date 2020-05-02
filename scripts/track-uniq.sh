for frame in $(seq 0 427); do grep "Entry f $frame " log | grep person | awk '{ print $11 }' | ruby -e "a = STDIN.map{|s| s.to_i}; puts a.length == a.uniq.length"; done
