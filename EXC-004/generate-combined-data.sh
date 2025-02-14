# Create the output directory
COMBINED_DIR="COMBINED-DATA"
mkdir -p "$COMBINED_DIR"

# List of sample numbers that require a leading zero
LEADING_ZERO_SAMPLES=("87" "88" "89" "90")  # Add your sample numbers here

# Process each sample directory in RAW-DATA
for g in RAW-DATA/*/; do
    Sample_names=$(basename "$g")
    
    # Extract the 2 or 3-digit number from the sample name
    # Example: "DNA087" → "087", "DNA83" → "83"
    sample_number=$(echo "$Sample_names" | grep -oP '\d{2,3}')

    # Check if the sample number requires a leading zero
    if [[ " ${LEADING_ZERO_SAMPLES[*]} " =~ " ${sample_number} " ]]; then
        sample_number="0$sample_number"  # Add a leading zero
    fi

    # Debugging: Print the sample number
    echo "Sample directory: $Sample_names"
    echo "Extracted sample number: $sample_number"

    # Get the culture name from the translation file
    Culture=$(awk -v s="$Sample_names" '$1 == s {print $2}' RAW-DATA/sample-translation.txt)

    # Check if Culture is found
    if [[ -z "$Culture" ]]; then
        echo "Warning: No translation found for sample $Sample_names. Skipping."
        continue
    fi

    # Initialize counters for MAG and BIN
    MAG_COUNT=1
    BIN_COUNT=1

    # Path to CheckM and GTDB files
    Checkm_file="$g/checkm.txt"
    GTDB_file="$g/gtdb.gtdbtk.tax"

    # Check if CheckM and GTDB files exist
    if [[ ! -f "$Checkm_file" ]]; then
        echo "Warning: CheckM file not found for sample $Sample_names. Skipping."
        continue
    fi
    if [[ ! -f "$GTDB_file" ]]; then
        echo "Warning: GTDB file not found for sample $Sample_names. Skipping."
        continue
    fi

    # Copy CheckM and GTDB files to COMBINED-DATA
    cp "$Checkm_file" "$COMBINED_DIR/$Culture-CHECKM.txt"
    cp "$GTDB_file" "$COMBINED_DIR/$Culture-GTDB-TAX.txt"

    # Process FASTA files in the bins/ directory
    for fasta_file in "$g/bins/"*.fasta; do
        file_name=$(basename "$fasta_file")

        # Skip "bin-unbinned.fasta" but copy it as XXX_UNBINNED.fa
        if [[ "$file_name" == "bin-unbinned.fasta" ]]; then
            cp "$fasta_file" "$COMBINED_DIR/${Culture}_UNBINNED.fa"
            continue
        fi

        # Extract the bin number from the .fasta file name
        # Example: If the file name is "bin-18.fasta", the bin number is "18"
        bin_number=$(echo "$file_name" | sed -E 's/bin-([0-9]+)\.fasta/\1/')

        # Debugging: Print the bin number
        echo "Processing .fasta file: $file_name"
        echo "Extracted bin number: $bin_number"

        # Construct the matching name in the format "ms<number>_megahit_metabat_bin-<number>"
        # Example: If the sample number is "087" and the bin number is "18", the matching name is "ms087_megahit_metabat_bin-18"
        transformed_name="ms${sample_number}_megahit_metabat_bin-${bin_number}"

        # Debugging: Print the transformed name
        echo "Constructed transformed name: $transformed_name"

        # Extract Completeness and Contamination from CheckM file using the transformed name
        completion=$(awk -v file="$transformed_name" '$1 == file {print $13}' "$Checkm_file")
        contamination=$(awk -v file="$transformed_name" '$1 == file {print $14}' "$Checkm_file")

        # Debugging: Print the extracted values
        echo "Completeness: $completion, Contamination: $contamination"

        # Check if completeness and contamination were extracted
        if [[ -z "$completion" || -z "$contamination" ]]; then
            echo "Warning: Completeness or contamination not found for $file_name (transformed name: $transformed_name). Skipping."
            continue
        fi

        # Conditional check for MAG and BIN
        if (( $(echo "$completion > 50 && $contamination < 5" | bc -l) )); then
            YYY="MAG"
            echo "$file_name classified as MAG"
        else
            YYY="BIN"  # Anything not MAG is BIN
        fi

        # Assign sequential number for MAG or BIN
        if [[ "$YYY" == "MAG" ]]; then
            ZZZ=$(printf "%03d" $MAG_COUNT)  # Zero-padded MAG number
            MAG_COUNT=$((MAG_COUNT + 1))  # Increment MAG count
        elif [[ "$YYY" == "BIN" ]]; then
            ZZZ=$(printf "%03d" $BIN_COUNT)  # Zero-padded BIN number
            BIN_COUNT=$((BIN_COUNT + 1))  # Increment BIN count
        fi

        # Construct the new filename and copy the file
        NEW_NAME="${Culture}_${YYY}_${ZZZ}.fa"
        cp "$fasta_file" "$COMBINED_DIR/$NEW_NAME"

        #Changing the defline

        sed -i "s/>bin/>${Culture}/g" "$COMBINED_DIR/$NEW_NAME"


    done
done


echo "TASK DONE"
