import csv
import json
import sys
from collections import defaultdict
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit(
        "Uso: python scripts/resumir_prueba.py SAMPLESHEET CARPETA_RESULTADOS"
    )

samplesheet = Path(sys.argv[1])
resultados = Path(sys.argv[2])
destino = resultados / "resumen_entrega2"
destino.mkdir(parents=True, exist_ok=True)


def leer_json(ruta):
    with ruta.open() as archivo:
        return json.load(archivo)


def guardar_csv(nombre, filas):
    with (destino / nombre).open("w", newline="") as archivo:
        escritor = csv.DictWriter(archivo, fieldnames=list(filas[0]))
        escritor.writeheader()
        escritor.writerows(filas)


with samplesheet.open(newline="") as archivo:
    entradas = list(csv.DictReader(archivo))

if len(entradas) != 12 or len({r["sample"] for r in entradas}) != 8:
    raise SystemExit("Se esperaban 12 runs y 8 muestras.")

if len({r["run"] for r in entradas}) != 12:
    raise SystemExit("Hay identificadores de run duplicados.")

with (resultados / "reportes/trace.tsv").open(newline="") as archivo:
    tareas = list(csv.DictReader(archivo, delimiter="\t"))

if len(tareas) != 45 or any(
    t["status"] not in ("COMPLETED", "CACHED") or str(t["exit"]) != "0"
    for t in tareas
):
    raise SystemExit("El trace no confirma 45 tareas exitosas.")

filas_runs = []
pares_por_muestra = defaultdict(int)
runs_por_muestra = defaultdict(int)

for entrada in entradas:
    muestra, run = entrada["sample"], entrada["run"]
    reporte = leer_json(resultados / "fastp" / f"{run}_fastp.json")
    antes = reporte["summary"]["before_filtering"]
    despues = reporte["summary"]["after_filtering"]

    # En estas salidas paired-end, total_reads suma R1 y R2.
    if antes["total_reads"] != 200000:
        raise SystemExit(f"{run}: no entraron las 200.000 lecturas esperadas.")
    if despues["total_reads"] % 2:
        raise SystemExit(f"{run}: conteo posterior impar; revisar.")

    pares_antes = antes["total_reads"] // 2
    pares_despues = despues["total_reads"] // 2
    pares_por_muestra[muestra] += pares_despues
    runs_por_muestra[muestra] += 1

    filas_runs.append({
        "sample": muestra,
        "run": run,
        "test_observed_pairs": pares_antes,
        "retained_pairs": pares_despues,
        "retained_percent": round(100 * pares_despues / pares_antes, 2),
        "q30_before_percent": round(100 * antes["q30_rate"], 2),
        "q30_after_percent": round(100 * despues["q30_rate"], 2),
        "test_r1_bytes": Path(entrada["fastq_1"]).stat().st_size,
        "test_r2_bytes": Path(entrada["fastq_2"]).stat().st_size,
    })

filas_muestras = []
for muestra in sorted(pares_por_muestra):
    carpeta = resultados / "salmon" / muestra
    reporte = leer_json(carpeta / "aux_info/meta_info.json")

    if reporte["num_processed"] != pares_por_muestra[muestra]:
        raise SystemExit(
            f"{muestra}: Salmon no procesó la suma esperada de pares de fastp."
        )
    if not (carpeta / "quant.sf").is_file():
        raise SystemExit(f"{muestra}: falta quant.sf.")

    filas_muestras.append({
        "sample": muestra,
        "runs": runs_por_muestra[muestra],
        "processed_fragments": reporte["num_processed"],
        "mapped_fragments": reporte["num_mapped"],
        "mapped_percent": round(reporte["percent_mapped"], 2),
        "library_type": reporte.get("detected_library_type", ""),
        "mean_fragment_length": round(reporte["frag_length_mean"], 2),
    })

guardar_csv("resumen_runs.csv", filas_runs)
guardar_csv("resumen_muestras.csv", filas_muestras)
guardar_csv("resumen_tareas.csv", tareas)

fuente = Path("metadata/source/ena_SRP338257.tsv")
if fuente.is_file():
    with fuente.open(newline="") as archivo:
        ena = {
            fila["run_accession"]: fila
            for fila in csv.DictReader(archivo, delimiter="\t")
        }

    inventario = []
    for fila in filas_runs:
        run = fila["run"]
        if run not in ena:
            raise SystemExit(f"{run}: no encontrado en la tabla de ENA.")

        registro = ena[run]
        inventario.append({
            "sample": fila["sample"],
            "run": run,
            "test_observed_pairs": fila["test_observed_pairs"],
            "test_r1_bytes": fila["test_r1_bytes"],
            "test_r2_bytes": fila["test_r2_bytes"],
            "ena_library_layout": registro["library_layout"],
            "ena_read_count_reported": registro["read_count"],
            "ena_base_count": registro["base_count"],
            "ena_fastq_bytes": registro["fastq_bytes"],
            "ena_fastq_md5": registro["fastq_md5"],
            "ena_fastq_ftp": registro["fastq_ftp"],
        })

    guardar_csv("inventario_datos.csv", inventario)

print("Confirmadas: 45 tareas exitosas, 12 runs y 8 cuantificaciones.")
print("Confirmada: suma de pares de fastp recibida por Salmon por muestra.")
print(f"Tablas guardadas en: {destino}")