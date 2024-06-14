#!/bin/bash


echo "[$(date '+%H:%M:%S')] --- START OF ORCA CALCULATION SCRIPT ---"

INPUT_DIR="./orca_files_lomonosov2"
OUT_DIR="${INPUT_DIR}/out"
TMP_DIR="${INPUT_DIR}/tmp"
INP_DIR="${INPUT_DIR}/inp"

# Подготовка директорий
mkdir -p "$TMP_DIR" "$OUT_DIR" "$INP_DIR"
echo "[$(date '+%H:%M:%S')] [INFO] Directories prepared."
rm -rf "$TMP_DIR"/*
echo "[$(date '+%H:%M:%S')] [INFO] Temporary directory cleared."

# Подсчёт файлов
total_files=$(find "$INPUT_DIR" -name '*.inp' | wc -l)
completed_files=$(find "$OUT_DIR" -name '*.out' | wc -l)
echo "[$(date '+%H:%M:%S')] [INFO] Total files: $total_files, Completed: $completed_files, Remaining: $((total_files - completed_files))"

# Функция обработки файла
process_file() {
  local inp_file=$1
  local base_name=$(basename "$inp_file" .inp)
  local tmp_out_file="$TMP_DIR/$base_name.out"

  echo "[$(date '+%H:%M:%S')] [INFO] Processing $inp_file"
  mv "$inp_file" "$TMP_DIR/$base_name.inp"

  /home/nikolenko/work/orca/orca/orca "$TMP_DIR/$base_name.inp" > "$tmp_out_file"
  
  if [ $? -eq 0 ]; then
    echo "[$(date '+%H:%M:%S')] [SUCCESS] Completed: $base_name"
    mv "$tmp_out_file" "$OUT_DIR/"
    mv "$TMP_DIR/$base_name.inp" "$INP_DIR/"
    find "$TMP_DIR" -type f -name "$base_name*" ! -name "*.inp" -exec mv {} "$OUT_DIR/" \;
  else
    echo "[$(date '+%H:%M:%S')] [ERROR] Failed: $base_name"
    touch "$OUT_DIR/$base_name.ERROR"
    return 1
  fi
}

# Получение списка молекул
mapfile -t molecules < <(find "$INPUT_DIR" -name '*.inp' -exec basename {} .inp \; | cut -d'_' -f1 | sort -u)

# Основной цикл
for molecule in "${molecules[@]}"; do
  for conformation in {0..4}; do
    error_occurred=0
    for charge in 1 0 -1; do
      if [ $error_occurred -eq 0 ]; then
        inp_file="${INPUT_DIR}/${molecule}_conformation_optimized_${conformation}_${charge}.inp"
        if [ -f "$inp_file" ] && [ ! -f "${inp_file%.inp}.out" ]; then
          process_file "$inp_file" || error_occurred=1
        else
          echo "[$(date '+%H:%M:%S')] [INFO] Skipping $inp_file"
        fi
      else
        echo "[$(date '+%H:%M:%S')] [INFO] Skipping remaining charges due to an error."
        break
      fi
    done
    if [ $error_occurred -eq 1 ]; then break; fi
  done
done

echo "[$(date '+%H:%M:%S')] --- END OF ORCA CALCULATION SCRIPT ---"
