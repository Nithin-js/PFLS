num_sequences=$(grep -c '>' $1)
# To count the total length of the sequences
total_length=$(grep -v '>' $1 | wc -c)
#Longest seq
length_of_the_longest_sequence=$(awk '/>/ {if (seq) print seq; print; seq=""; next} {seq=seq $0} END {print seq}' $1 | grep -v '>'| awk '{print length($0)}' | sort -n | tail -n 1)
#Shortest seq
length_of_the_shortest_sequence=$(awk '/>/ {if (seq) print seq; print; seq=""; next} {seq=seq $0} END {print seq}' $1 | grep -v '>'| awk '{print length($0)}' | sort -n | head -n 1)
#GC count
gc_count=$(grep -v '>' $1 | awk '{gc_count += gsub(/[GgCc]/, "", $1)} END {print gc_count}')


echo "FASTA File Statistics:"
echo "Number of sequences: $num_sequences"
echo "Total length of sequences: $total_length"
echo "Length of the longest sequence: $length_of_the_longest_sequence" 
echo "Length of the shortest sequence: $length_of_the_shortest_sequence"
echo "Average sequence length: $(($total_length/$num_sequences))"
echo "GC Content (%): $((100* $gc_count/$total_length)) %"