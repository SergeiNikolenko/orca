#!/bin/bash

#SBATCH --job-name=janpa
#SBATCH -n12
#SBATCH --output=orca2nao.log
#SBATCH --error=orca2nao.err

# Initialization
INPUT="."
MAX_CHILDREN=56

# Create directories for the outputs
ORCA_DONE="$INPUT/orca_done"
JANPA_DONE="$INPUT/janpa_done"
MOLDEN_DIR="$INPUT/janpa"

mkdir -p "$ORCA_DONE"
mkdir -p "$JANPA_DONE"
mkdir -p "$MOLDEN_DIR"

# Check for necessary files and directories
if [ ! -d "$MOLDEN_DIR" ]; then
    echo "[$(date '+%H:%M:%S')] [ERROR] Molden directory not found: $MOLDEN_DIR"
    exit 1
fi

if [ ! -f "$MOLDEN_DIR/molden2molden.jar" ] || [ ! -f "$MOLDEN_DIR/janpa.jar" ]; then
    echo "[$(date '+%H:%M:%S')] [ERROR] Required JAR files not found in: $MOLDEN_DIR"
    exit 1
fi

# Logging start
echo "[$(date '+%H:%M:%S')] --- START OF SCRIPT ---"

# Count total and remaining files
total_files=$(find $INPUT/orca_calc -type f -name '*.out' | wc -l)
processed_files=$(find "$JANPA_DONE" -type f -name '*.out' | wc -l)
remaining_files=$((total_files - processed_files))

echo "[$(date '+%H:%M:%S')] [INFO] Total files: $total_files, Processed: $processed_files, Remaining: $remaining_files"

# Start computation
JOBS_COUNTER=0
MY_PID=$$
for filename in $(find $INPUT/orca_calc -type f -name '*.out')
do
    JOBS_COUNTER=$(ps ax -Ao ppid | grep -c $MY_PID)
    while [ $JOBS_COUNTER -ge $MAX_CHILDREN ]
    do
        JOBS_COUNTER=$(ps ax -Ao ppid | grep -c $MY_PID)
    done
    base_name=$(basename "$filename" | cut -d. -f1)
    echo "[$(date '+%H:%M:%S')] [INFO] Processing $filename"

    # Search for a corresponding GBW file
    gbw_file=$(find "$INPUT/orca_calc" -type f -name "${base_name}*.gbw" | head -n 1)
    if [ -z "$gbw_file" ]; then
        echo "[$(date '+%H:%M:%S')] [ERROR] GBW file not found for: $base_name"
        continue
    fi

    /home/nikolenko/work/orca/orca/orca_2mkl "$INPUT/orca_calc/$base_name" -molden

    if [ -f "$INPUT/orca_calc/${base_name}.out" ] && [ -n "$gbw_file" ]; then
        mv "$INPUT/orca_calc/${base_name}.out" "$ORCA_DONE/${base_name}_ok.out"
        mv "$gbw_file" "$ORCA_DONE/$(basename "$gbw_file" .gbw)_ok.gbw"
    else
        echo "[$(date '+%H:%M:%S')] [ERROR] ORCA files not found: ${base_name}.out or $gbw_file"
        continue
    fi

    molden_input="${base_name}.molden.input"
    if [ -f "$INPUT/orca_calc/$molden_input" ]; then
        mv "$INPUT/orca_calc/$molden_input" "$MOLDEN_DIR/${base_name}.molden"
    else
        echo "[$(date '+%H:%M:%S')] [ERROR] Molden input file not found: $molden_input"
        continue
    fi

    cd $MOLDEN_DIR

    java -jar molden2molden.jar -orca3signs -fromorca3bf -i "${base_name}.molden" -o "${base_name}_ok.molden" > /dev/null
    java -jar janpa.jar "${base_name}_ok.molden" > "${base_name}.out"

    rm "${base_name}.molden"
    rm "${base_name}_ok.molden"

    if [ -f "${base_name}.out" ]; then
        mv "${base_name}.out" "$JANPA_DONE/${base_name}.out"
    else
        echo "[$(date '+%H:%M:%S')] [ERROR] JANPA output file not found: ${base_name}.out"
    fi

    cd $INPUT

    processed_files=$((processed_files + 1))
    remaining_files=$((total_files - processed_files))
    echo "[$(date '+%H:%M:%S')] [INFO] Completed $filename"
done

while [ $JOBS_COUNTER -gt 1 ]
do
    JOBS_COUNTER=$(ps ax -Ao ppid | grep -c $MY_PID)
done

echo "[$(date '+%H:%M:%S')] --- END OF SCRIPT ---"
