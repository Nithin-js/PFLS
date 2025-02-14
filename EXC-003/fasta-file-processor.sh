num_sequences=$(grep -c '>' $1)
# To count the total length of the sequences
total_length=$(awk '/^>/ {next}; {totallength += length $0} END{print totallength}' $1)
#Longest seq
length_of_the_longest_sequence=$(awk '/>/ {if (seq) print seq; print; seq=""; next} {seq=seq $0} END {print seq}' $1 | grep -v '>'| awk '{print length($0)}' | sort -n | tail -n 1)
#Shortest seq
length_of_the_shortest_sequence=$(awk '/>/ {if (seq) print seq; print; seq=""; next} {seq=seq $0} END {print seq}' $1 | grep -v '>'| awk '{print length($0)}' | sort -n | head -n 1)
#GC count
gc_count=$(grep -v '>' $1 | awk '{gc_count += gsub(/[GgCc]/, "", $1)} END {print gc_count}')

gc_content=$(echo "scale=2; ($gc_count/$total_length)*100" | bc)

echo "FASTA File Statistics:"
echo "----------------------"
echo "Number of sequences: $num_sequences"
echo "Total length of sequences: $total_length"
echo "Length of the longest sequence: $length_of_the_longest_sequence" 
echo "Length of the shortest sequence: $length_of_the_shortest_sequence"
echo "Average sequence length: $(($total_length/$num_sequences))"
echo "GC Content (%): $gc_content"
 