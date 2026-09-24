#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

salida="results/prueba_preprocesamiento/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$salida/reportes"

echo "Resultados: $salida"

nextflow run workflow/main.nf \
  -profile local \
  --samplesheet metadata/samplesheet_test.csv \
  --output_dir "$salida" \
  -with-report "$salida/reportes/report.html" \
  -with-timeline "$salida/reportes/timeline.html" \
  -with-trace "$salida/reportes/trace.tsv"
