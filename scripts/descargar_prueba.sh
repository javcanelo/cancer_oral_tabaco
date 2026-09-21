# Ejecutar desde la raíz el proyecto
# extrae los primeros 100.000 registros de SRR16013054
# SRR16013054 = prueba de pipeline (OSCC_4-P)

# --split-files: separa las lecturas paired-end en R1 y R2.
# --skip-technical: excluye lecturas técnicas
# -X 100000: limita l extracción a los primeros 100.000 spots
# --gzip: comprime los archivo FASTQ generados
# --outdir data/test: guarda los archivos en data/test

mkdir -p data/test

fastq-dump SRR16013054 --split-files --skip-technical -X 100000 --gzip --outdir data/test