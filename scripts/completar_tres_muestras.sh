#!/usr/bin/env bash
set -euo pipefail

cd "$HOME/cancer_oral_tabaco"
proyecto="$PWD"
base=/mnt/d/oscc_completo
raw="$base/raw"
resultados="$proyecto/results/pendientes_automatico"
trabajos="$base/work/pendientes_automatico"

mkdir -p "$raw" "$resultados" "$trabajos"

# Impide dos copias simultáneas de este script.
exec 9>"$base/completar_tres_muestras.lock"
flock -n 9 || {
    echo "Este script ya está ejecutándose."
    exit 1
}

# Evita competir con una ejecución anterior.
if pgrep -u "$(id -u)" -f \
    '[n]extflow.*workflow/main.nf|[f]astq-dump|[f]asterq-dump' >/dev/null; then
    echo "Hay otra descarga o pipeline activo. No se inició otro."
    exit 1
fi

for herramienta in nextflow fastq-dump fastp fastqc salmon multiqc; do
    command -v "$herramienta" >/dev/null || {
        echo "Falta $herramienta. Debes activar oscc_rnaseq."
        exit 1
    }
done

test -s workflow/main.nf
test -s reference/salmon_gencode_v50/info.json

hilos=$(nproc)
if (( hilos > 6 )); then
    hilos=6
fi

config="$resultados/recursos.config"

cat > "$config" <<EOF
executor {
    queueSize = 1
    cpus = $hilos
    memory = '6 GB'
}

process {
    withName: salmon_quant {
        cpus = $hilos
        memory = '5 GB'
        maxForks = 1
    }

    withName: fastp {
        cpus = 2
        memory = '3 GB'
        maxForks = 1
        publishDir = [
            path: { "\${params.output_dir}/fastp" },
            mode: 'copy',
            pattern: '*_fastp.*'
        ]
    }

    withName: 'fastqc|fastqc_post_trimming' {
        cpus = 2
        memory = '1 GB'
    }

    withName: multiqc {
        cpus = 1
        memory = '2 GB'
    }
}
EOF

export NXF_OPTS="${NXF_OPTS:-} -Xmx1g"

trap 'codigo=$?; echo "===== DETENIDO: código $codigo, línea $LINENO — $(date) ====="; exit "$codigo"' ERR

espacio() {
    local libre_d libre_c
    libre_d=$(df -B1 --output=avail /mnt/d | tail -n 1)
    libre_c=$(df -B1 --output=avail /mnt/c | tail -n 1)

    if (( libre_d < 50*1024*1024*1024 ||
          libre_c < 15*1024*1024*1024 )); then
        echo "Se detiene por espacio: requiere margen de 50 GiB en D y 15 GiB en C."
        df -h /mnt/c /mnt/d
        exit 1
    fi
}

descargar() {
    local run="$1"
    local temporal="$raw/${run}_descarga"
    local r1="$raw/${run}_1.fastq.gz"
    local r2="$raw/${run}_2.fastq.gz"
    local intento

    if [[ -s "$r1" && -s "$r2" ]]; then
        echo "===== VALIDANDO ARCHIVOS EXISTENTES: $run ====="
        gzip -t "$r1" "$r2"
        echo "===== $run DISPONIBLE ====="
        return
    fi

    if [[ -e "$r1" || -e "$r2" ]]; then
        echo "$run: par final incompleto; revisar antes de sobrescribir."
        exit 1
    fi

    mkdir -p "$temporal"

    for intento in 1 2 3; do
        espacio

        # fastq-dump no reanuda estos archivos:
        # elimina solo los dos FASTQ parciales del run actual.
        rm -f -- \
            "$temporal/${run}_1.fastq.gz" \
            "$temporal/${run}_2.fastq.gz"

        echo "===== DESCARGANDO $run: intento $intento/3 — $(date) ====="

        if fastq-dump "$run" \
            --split-files \
            --skip-technical \
            --gzip \
            --outdir "$temporal"
        then
            echo "===== VALIDANDO DESCARGA: $run — $(date) ====="

            if [[ -s "$temporal/${run}_1.fastq.gz" &&
                  -s "$temporal/${run}_2.fastq.gz" ]] &&
               gzip -t \
                   "$temporal/${run}_1.fastq.gz" \
                   "$temporal/${run}_2.fastq.gz"
            then
                mv -- "$temporal/${run}_1.fastq.gz" "$r1"
                mv -- "$temporal/${run}_2.fastq.gz" "$r2"
                rmdir "$temporal" 2>/dev/null || true

                echo "===== DESCARGA COMPLETA: $run — $(date) ====="
                du -h "$r1" "$r2"
                return
            fi
        fi

        echo "Falló el intento $intento para $run."
        if (( intento < 3 )); then
            sleep 15
        fi
    done

    echo "No se pudo descargar $run tras tres intentos."
    exit 1
}

procesar_muestra() {
    local muestra="$1"
    shift
    local runs=("$@")
    local salida="$resultados/$muestra"
    local trabajo="$trabajos/$muestra"
    local nombre="automatico_pendientes_${muestra//-/_}"
    local fecha run
    local -a opciones=()

    if [[ -s "$salida/reportes/COMPLETO.txt" &&
          -s "$salida/salmon/$muestra/quant.sf" &&
          -s "$salida/salmon/$muestra/aux_info/meta_info.json" ]]; then
        echo "===== $muestra YA TERMINÓ: se omite ====="
        return
    fi

    # Primero obtiene TODOS los runs de esta muestra.
    for run in "${runs[@]}"; do
        descargar "$run"
    done

    espacio
    mkdir -p "$salida/reportes" "$trabajo"

    if [[ ! -f "$salida/reportes/INICIADO.txt" ]]; then
        {
            echo "sample,run,fastq_1,fastq_2"
            for run in "${runs[@]}"; do
                echo "$muestra,$run,$raw/${run}_1.fastq.gz,$raw/${run}_2.fastq.gz"
            done
        } > "$salida/reportes/samplesheet.csv"

        cp "$config" "$salida/reportes/recursos.config"
        cp nextflow.config "$salida/reportes/"
        cp -r workflow "$salida/reportes/workflow"

        {
            nextflow -version
            fastp --version
            fastqc --version
            salmon --version
            multiqc --version
        } > "$salida/reportes/versiones.txt" 2>&1

        opciones=(-name "$nombre")
    else
        opciones=(-resume "$nombre")
    fi

    fecha=$(date +%Y%m%d_%H%M%S)
    date > "$salida/reportes/INICIADO.txt"

    echo "===== INICIANDO PIPELINE: $muestra — $(date) ====="
    echo "Resultados: $salida"
    echo "Intermedios: $trabajo"

    nextflow \
        -c "$salida/reportes/recursos.config" \
        run workflow/main.nf \
        -profile local \
        "${opciones[@]}" \
        --samplesheet "$salida/reportes/samplesheet.csv" \
        --salmon_index "$proyecto/reference/salmon_gencode_v50" \
        --output_dir "$salida" \
        -work-dir "$trabajo" \
        -ansi-log false \
        -with-report "$salida/reportes/report_${fecha}.html" \
        -with-timeline "$salida/reportes/timeline_${fecha}.html" \
        -with-trace "$salida/reportes/trace_${fecha}.tsv" \
        2>&1 | tee -a "$salida/reportes/ejecucion.log"

    test -s "$salida/salmon/$muestra/quant.sf"
    test -s "$salida/salmon/$muestra/aux_info/meta_info.json"

    date > "$salida/reportes/COMPLETO.txt"
    echo "===== PIPELINE TERMINADO: $muestra — $(date) ====="
}

procesar_muestra OSCC_10-P SRR16013070
procesar_muestra OSCC_13-P SRR16013082 SRR16013083 SRR16013084
procesar_muestra OSCC_11-P SRR16013072 SRR16013073 SRR16013074

echo "===== TERMINARON LAS TRES MUESTRAS — $(date) ====="
