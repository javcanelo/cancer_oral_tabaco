#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

nextflow run workflow/main.nf \
  -profile local \
  --samplesheet metadata/samplesheet_test.csv \
  --output_dir results/prueba_qc_corregida \
  -with-report results/prueba_qc_corregida_report.html \
  -with-timeline results/prueba_qc_corregida_timeline.html \
  -with-trace results/prueba_qc_corregida_trace.tsv
