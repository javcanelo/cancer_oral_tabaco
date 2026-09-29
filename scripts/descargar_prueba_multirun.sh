#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

python - <<'PY'
import csv
import gzip
import shutil
import subprocess
from pathlib import Path

if shutil.which("fastq-dump") is None:
    raise SystemExit("No se encontró fastq-dump en el ambiente activo.")

with open("metadata/samplesheet_test_all.csv", newline="") as archivo:
    entradas = list(csv.DictReader(archivo))

for entrada in entradas:
    run = entrada["run"]
    r1 = Path(entrada["fastq_1"])
    r2 = Path(entrada["fastq_2"])

    if r1.parent != r2.parent:
        raise SystemExit(f"{run}: R1 y R2 deben tener el mismo destino.")

    if r1.name != f"{run}_1.fastq.gz" or r2.name != f"{run}_2.fastq.gz":
        raise SystemExit(f"{run}: nombres de FASTQ inesperados.")

    r1.parent.mkdir(parents=True, exist_ok=True)

    if not r1.exists() and not r2.exists():
        subprocess.run(
            [
                "fastq-dump", run,
                "--split-files",
                "--skip-technical",
                "-X", "100000",
                "--gzip",
                "--outdir", str(r1.parent),
            ],
            check=True,
        )
    elif not r1.exists() or not r2.exists():
        raise SystemExit(
            f"{run}: solo existe uno de los mates; revisar antes de descargar."
        )

    for ruta in (r1, r2):
        with gzip.open(ruta, "rb") as archivo:
            lineas = sum(1 for _ in archivo)
        if lineas != 400000:
            raise SystemExit(
                f"{ruta}: se esperaban 100.000 registros FASTQ de cuatro líneas."
            )

    print(f"{run}: ambos FASTQ disponibles, con 100.000 lecturas por archivo.")
PY