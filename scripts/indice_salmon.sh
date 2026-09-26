#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
mkdir -p reference docs/reproducibilidad

if [ ! -s reference/gencode.v50.transcripts.fa.gz ]; then
    curl -fL --retry 3 \
        https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/gencode.v47.transcripts.fa.gz \
        -o reference/gencode.v50.transcripts.fa.gz
fi

gzip -t reference/gencode.v50.transcripts.fa.gz

sha256sum reference/gencode.v50.transcripts.fa.gz \
    > docs/reproducibilidad/referencia.sha256

salmon index \
    --transcripts reference/gencode.v50.transcripts.fa.gz \
    --index reference/salmon_gencode_v50 \
    --gencode \
    --kmerLen 31 \
    --threads 2 \
    2>&1 | tee docs/reproducibilidad/salmon_index.log
