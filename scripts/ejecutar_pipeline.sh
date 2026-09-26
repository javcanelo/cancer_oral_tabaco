#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

samplesheet="${1:-metadata/samplesheet_test.csv}"
indice="reference/salmon_gencode_v50"

for herramienta in nextflow fastqc fastp salmon multiqc; do
    if ! command -v "$herramienta" >/dev/null 2>&1; then
        echo "Falta la herramienta: $herramienta" >&2
        exit 1
    fi
done

if [[ ! -s "$samplesheet" ]]; then
    echo "Samplesheet ausente o vacío: $samplesheet" >&2
    exit 1
fi

if [[ ! -s "$indice/info.json" ]]; then
    echo "No se encontró la información del índice: $indice" >&2
    echo "Revisa la ejecución de scripts/indice_salmon.sh" >&2
    exit 1
fi

salida="results/pipeline/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$salida/reportes"

cp "$samplesheet" "$salida/reportes/samplesheet.csv"

{
    nextflow -version
    fastqc --version
    fastp --version
    salmon --version
    multiqc --version
} > "$salida/reportes/versiones.txt" 2>&1

echo "Samplesheet: $samplesheet"
echo "Resultados: $salida"

nextflow run workflow/main.nf \
    -profile local \
    --samplesheet "$samplesheet" \
    --salmon_index "$indice" \
    --output_dir "$salida" \
    -with-report "$salida/reportes/report.html" \
    -with-timeline "$salida/reportes/timeline.html" \
    -with-trace "$salida/reportes/trace.tsv"