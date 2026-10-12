#!/usr/bin/env bash
set -euo pipefail

cd "$HOME/cancer_oral_tabaco"
proyecto="$PWD"
base=/mnt/d/oscc_completo
raw="$base/raw"

mkdir -p "$raw" "$base/work"

exec 9>"$base/terminar_pendientes.lock"
flock -n 9 || {
    echo "Este script ya está ejecutándose."
    exit 1
}

if pgrep -f '[n]extflow.*workflow/main.nf|[f]astq-dump|[f]asterq-dump' >/dev/null; then
    echo "Hay otra descarga o pipeline activo. No se inició otro."
    exit 1
fi

for herramienta in nextflow fastq-dump fastp fastqc salmon multiqc; do
    command -v "$herramienta" >/dev/null || {
        echo "Falta $herramienta. Activa oscc_rnaseq."
        exit 1
    }
done

test -s nextflow.recuperacion.config || {
    echo "Falta nextflow.recuperacion.config."
    exit 1
}

test -s reference/salmon_gencode_v50/info.json || {
    echo "Falta el índice de Salmon."
    exit 1
}

export NXF_OPTS="${NXF_OPTS:-} -Xmx1g"

comprobar_espacio() {
    local libre_d libre_c
    libre_d=$(df -B1 --output=avail /mnt/d | tail -n 1)
    libre_c=$(df -B1 --output=avail /mnt/c | tail -n 1)

    if (( libre_d < 50*1024*1024*1024 || libre_c < 15*1024*1024*1024 )); then
        echo "Espacio insuficiente para continuar con este margen."
        df -h /mnt/c /mnt/d
        exit 1
    fi
}

descargar() {
    local run="$1"
    local temporal="$raw/${run}_descarga"
    local r1="$raw/${run}_1.fastq.gz"
    local r2="$raw/${run}_2.fastq.gz"

    if [[ -s "$r1" && -s "$r2" ]]; then
        echo "===== $run: comprobando par existente ====="
        if gzip -t "$r1" "$r2"; then
            echo "$run: disponible."
            return
        fi
        echo "$run: el par existente falló la comprobación; no se sobrescribió."
        exit 1
    fi

    if [[ -e "$r1" || -e "$r2" ]]; then
        echo "$run: hay un solo mate final. Revisar antes de continuar."
        exit 1
    fi

    comprobar_espacio
    mkdir -p "$temporal"

    # Solo elimina los dos archivos parciales de ESTE run.
    # fastq-dump reinicia la descarga; no continúa el archivo parcial.
    rm -f -- \
        "$temporal/${run}_1.fastq.gz" \
        "$temporal/${run}_2.fastq.gz"

    echo "===== DESCARGANDO $run — $(date) ====="

    fastq-dump "$run" \
        --split-files \
        --skip-technical \
        --gzip \
        --outdir "$temporal"

    test -s "$temporal/${run}_1.fastq.gz"
    test -s "$temporal/${run}_2.fastq.gz"

    echo "===== VALIDANDO $run — $(date) ====="
    gzip -t \
        "$temporal/${run}_1.fastq.gz" \
        "$temporal/${run}_2.fastq.gz"

    mv -- "$temporal/${run}_1.fastq.gz" "$r1"
    mv -- "$temporal/${run}_2.fastq.gz" "$r2"
    rmdir "$temporal" 2>/dev/null || true

    echo "===== DESCARGA TERMINADA $run — $(date) ====="
    du -h "$r1" "$r2"
}

procesar() {
    local muestra="$1"
    shift
    local runs=("$@")
    local salida="$proyecto/results/pendientes_oct06/$muestra"
    local trabajo="$base/work/pendientes_oct06/$muestra"
    local nombre="pendientes_oct06_${muestra//-/_}"
    local informe
    local -a reanudar=()

    if [[ -s "$salida/reportes/PIPELINE_COMPLETO.txt" ]]; then
        echo "===== $muestra: ya terminó con este script; se omite ====="
        return
    fi

    for run in "${runs[@]}"; do
        descargar "$run"
    done

    comprobar_espacio
    mkdir -p "$salida/reportes" "$trabajo"

    if [[ ! -f "$salida/reportes/INICIADO.txt" ]]; then
        {
            echo "sample,run,fastq_1,fastq_2"
            for run in "${runs[@]}"; do
                echo "$muestra,$run,$raw/${run}_1.fastq.gz,$raw/${run}_2.fastq.gz"
            done
        } > "$salida/reportes/samplesheet.csv"

        cp nextflow.recuperacion.config "$salida/reportes/"
        cp nextflow.config "$salida/reportes/"
        cp -r workflow "$salida/reportes/workflow"

        reanudar=(-name "$nombre")
    else
        reanudar=(-resume "$nombre")
    fi

    informe=$(date +%Y%m%d_%H%M%S)
    date > "$salida/reportes/INICIADO.txt"

    echo "===== PROCESANDO $muestra — $(date) ====="
    echo "Resultados: $salida"
    echo "Intermedios: $trabajo"

    nextflow \
        -c "$salida/reportes/nextflow.recuperacion.config" \
        run workflow/main.nf \
        -profile local \
        "${reanudar[@]}" \
        --samplesheet "$salida/reportes/samplesheet.csv" \
        --salmon_index "$proyecto/reference/salmon_gencode_v50" \
        --output_dir "$salida" \
        -work-dir "$trabajo" \
        -ansi-log false \
        -with-report "$salida/reportes/report_${informe}.html" \
        -with-timeline "$salida/reportes/timeline_${informe}.html" \
        -with-trace "$salida/reportes/trace_${informe}.tsv" \
        2>&1 | tee -a "$salida/reportes/ejecucion.log"

    test -s "$salida/salmon/$muestra/quant.sf"
    test -s "$salida/salmon/$muestra/aux_info/meta_info.json"

    date > "$salida/reportes/PIPELINE_COMPLETO.txt"
    echo "===== TERMINÓ $muestra — $(date) ====="
}

procesar OSCC_10-P SRR16013070
procesar OSCC_13-P SRR16013082 SRR16013083 SRR16013084
procesar OSCC_11-P SRR16013072 SRR16013073 SRR16013074

echo "===== TERMINARON LAS TRES MUESTRAS PENDIENTES ====="
python scripts/ver_estado.py
