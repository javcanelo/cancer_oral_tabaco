import csv
import json
import sys
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import urlopen

samplesheet = Path(sys.argv[1])

with samplesheet.open(newline="") as archivo:
    muestras = list(csv.DictReader(archivo))

consulta = urlencode({
    "accession": "SRP338257",
    "result": "read_run",
    "fields": "run_accession,fastq_ftp,fastq_bytes",
    "format": "json",
})

with urlopen(
    f"https://www.ebi.ac.uk/ena/portal/api/filereport?{consulta}",
    timeout=120,
) as respuesta:
    registros = json.load(respuesta)

ena = {r["run_accession"]: r for r in registros}
filas = []
total_completo = 0
total_prueba = 0

for muestra in muestras:
    run = muestra["run"]
    registro = ena[run]

    enlaces = registro["fastq_ftp"].split(";")
    tamanos = registro["fastq_bytes"].split(";")

    if len(enlaces) != len(tamanos):
        raise RuntimeError(f"{run}: tamaños y archivos de ENA no coinciden.")

    archivos = dict(zip(enlaces, tamanos))
    completo = 0

    for mate in (1, 2):
        encontrados = [
            int(tamano)
            for enlace, tamano in archivos.items()
            if enlace.endswith(f"/{run}_{mate}.fastq.gz")
        ]
        if len(encontrados) != 1:
            raise RuntimeError(f"{run}: no se identificó el tamaño de R{mate}.")
        completo += encontrados[0]

    prueba = sum(
        Path(muestra[campo]).stat().st_size
        for campo in ("fastq_1", "fastq_2")
    )

    total_completo += completo
    total_prueba += prueba
    filas.append(
        f"| {muestra['sample']} | {run} | "
        f"{completo / 1024**3:.2f} | {prueba / 1024**2:.2f} |"
    )

print("| Muestra | Run | FASTQ completos R1 + R2 (GiB) | "
      "Subconjunto R1 + R2 (MiB) |")
print("|---|---|---:|---:|")
print("\n".join(filas))
print(
    f"| **Total** | **{len(muestras)} runs** | "
    f"**{total_completo / 1024**3:.2f}** | "
    f"**{total_prueba / 1024**2:.2f}** |"
)