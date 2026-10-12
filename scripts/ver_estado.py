import csv
import json
from pathlib import Path

proyecto = Path.home() / "cancer_oral_tabaco"
raw = Path("/mnt/d/oscc_completo/raw")
raices = [
    proyecto / "results",
    Path("/mnt/d/oscc_completo/results"),
]

def leer_csv(ruta, separador=","):
    with open(ruta, newline="", encoding="utf-8-sig") as f:
        return list(csv.DictReader(f, delimiter=separador))

metadata = leer_csv(proyecto / "metadata/sample_metadata.csv")
entradas = leer_csv(proyecto / "metadata/samplesheet.csv")

runs_por_muestra = {
    m["sample"]: [
        r["run"] for r in entradas if r["sample"] == m["sample"]
    ]
    for m in metadata
}

hallazgos = {m["sample"]: [] for m in metadata}
avisos = []

for raiz in raices:
    if not raiz.exists():
        continue

    for hoja in raiz.rglob("samplesheet.csv"):
        if hoja.parent.name != "reportes":
            continue

        carpeta = hoja.parent.parent

        try:
            filas = leer_csv(hoja)

            # Solo ejecuciones con nuestros FASTQ completos.
            filas = [
                r for r in filas
                if r.get("fastq_1") ==
                str(raw / f"{r.get('run')}_1.fastq.gz")
                and r.get("fastq_2") ==
                str(raw / f"{r.get('run')}_2.fastq.gz")
            ]
            if not filas:
                continue

            # Reúne los estados registrados en las reanudaciones.
            estados = {}
            traces = sorted(
                hoja.parent.glob("trace*.tsv"),
                key=lambda p: p.stat().st_mtime
            )

            for trace in traces:
                for tarea in leer_csv(trace, "\t"):
                    nombre = tarea.get("name", "")
                    proceso, _, etiqueta = nombre.partition(" (")
                    proceso = proceso.split(":")[-1].strip()
                    etiqueta = etiqueta.rstrip(")")
                    estados[(proceso, etiqueta)] = (
                        tarea.get("status") in ("COMPLETED", "CACHED")
                        and tarea.get("exit") == "0"
                    )

            for muestra in sorted({r["sample"] for r in filas}):
                if muestra not in hallazgos:
                    continue

                esperados = runs_por_muestra[muestra]
                presentes = {
                    r["run"] for r in filas if r["sample"] == muestra
                }

                if presentes != set(esperados):
                    hallazgos[muestra].append((
                        0, "RUNS INCOMPLETOS EN SAMPLESHEET", carpeta
                    ))
                    continue

                quant_dir = carpeta / "salmon" / muestra
                quant = quant_dir / "quant.sf"
                meta = quant_dir / "aux_info/meta_info.json"

                if not quant.is_file() or not meta.is_file():
                    hallazgos[muestra].append((
                        0, "SIN CUANTIFICACIÓN PUBLICADA", carpeta
                    ))
                    continue

                with open(meta) as f:
                    datos = json.load(f)

                with open(quant) as f:
                    tabla = csv.DictReader(f, delimiter="\t")
                    quant_valido = (
                        "NumReads" in (tabla.fieldnames or [])
                        and next(tabla, None) is not None
                    )

                retenidos = 0
                fastp_completo = True

                for run in esperados:
                    archivo = carpeta / "fastp" / f"{run}_fastp.json"
                    if not archivo.is_file():
                        fastp_completo = False
                        break
                    with open(archivo) as f:
                        j = json.load(f)
                    retenidos += (
                        j["summary"]["after_filtering"]["total_reads"] / 2
                    )

                consistente = (
                    quant_valido
                    and fastp_completo
                    and retenidos > 0
                    and datos.get("num_processed") == retenidos
                    and datos.get("num_mapped", 0) > 0
                )

                if not consistente:
                    hallazgos[muestra].append((
                        0, "REVISAR CUANTIFICACIÓN / FASTP", carpeta
                    ))
                    continue

                tareas_esperadas = [("salmon_quant", muestra)]
                for run in esperados:
                    for proceso in ("fastqc", "fastp", "fastqc_post_trimming"):
                        tareas_esperadas.append(
                            (proceso, f"{muestra}:{run}")
                        )

                tareas_ok = all(
                    estados.get(tarea, False)
                    for tarea in tareas_esperadas
                )
                multiqc_ok = (
                    any(
                        proceso == "multiqc" and correcto
                        for (proceso, etiqueta), correcto in estados.items()
                    )
                    and (
                        carpeta / "multiqc/multiqc_report.html"
                    ).is_file()
                )

                if tareas_ok and multiqc_ok:
                    nivel, estado = 3, "COMPLETO VERIFICADO"
                elif estados.get(("salmon_quant", muestra), False):
                    nivel, estado = 2, "SALMON OK; CIERRE NO CONFIRMADO"
                else:
                    nivel, estado = 1, "QUANT CONSISTENTE; FALTA TRACE EXITOSO"

                hallazgos[muestra].append((nivel, estado, carpeta))

        except Exception as error:
            avisos.append(f"{hoja}: {error}")

print("\nESTADO ACTUAL DE LAS OCHO MUESTRAS\n")

for m in metadata:
    muestra = m["sample"]
    runs = runs_por_muestra[muestra]

    print(f"{muestra} | {m['group']}")

    for run in runs:
        pares = [
            raw / f"{run}_1.fastq.gz",
            raw / f"{run}_2.fastq.gz",
        ]
        disponibles = sum(
            p.is_file() and p.stat().st_size > 0 for p in pares
        )
        temporal = raw / f"{run}_descarga"

        if disponibles == 2:
            descarga = "PAR FINAL PRESENTE"
        elif disponibles == 1:
            descarga = "SOLO UN MATE FINAL: REVISAR"
        elif temporal.exists():
            descarga = "TEMPORAL: DESCARGA SIN CONFIRMAR"
        else:
            descarga = "SIN FASTQ"

        print(f"  {run}: {descarga}")

    resultados = hallazgos[muestra]
    if resultados:
        nivel, estado, carpeta = max(resultados, key=lambda x: x[0])
        print(f"  PIPELINE: {estado}")
        print(f"  Evidencia: {carpeta}")
    else:
        print("  PIPELINE: SIN EJECUCIÓN DE DATOS COMPLETOS ENCONTRADA")
    print()

print("PAR FINAL PRESENTE comprueba existencia y tamaño, no relee gzip.")
print("SIN CUANTIFICACIÓN no distingue una tarea activa de una fallida.")
print("COMPLETO VERIFICADO exige trace exitoso, cuantificación")
print("consistente con fastp y MultiQC presente y exitoso.")

if avisos:
    print("\nARCHIVOS QUE NO SE PUDIERON INTERPRETAR:")
    for aviso in avisos:
        print(" -", aviso)
