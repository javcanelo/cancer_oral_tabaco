# Workflow del proyecto

Workflow propio en Nextflow DSL2 para ocho muestras tumorales
de GSE184616 y análisis posterior en R.

```mermaid
flowchart TD
    A["Samplesheet: 8 muestras y 12 runs"] --> B["Lecturas FASTQ paired-end"]
    B --> C["FastQC por run"]
    C --> D{"¿Requieren trimming?"}
    D -->|Sí| E["Trimming y revisión de calidad"]
    D -->|No| F["Agrupación de runs por muestra"]
    E --> F
    F --> G["Salmon: cuantificación"]
    R["Referencia e índice"] --> G
    G --> H["R: tximport y resumen génico"]
    M["Metadatos: 4 ever y 4 never"] --> I["DESeq2: filtrado y normalización"]
    H --> I
    I --> J["VST: PCA y clustering"]
    I --> K["Expresión diferencial y FDR"]
    K --> L["Enriquecimiento e interpretación"]
    C --> Q["MultiQC"]
    E --> Q
    G --> Q
```

## Decisiones de diseño

- La necesidad de trimming se decidirá mediante revisión de calidad.
- Los runs se agruparán manteniendo R1 y R2 asociados.
- MultiQC integrará los reportes de las herramientas.
- tximport permitirá pasar de cuantificaciones de transcritos
  a información a nivel de gen para el análisis.
- Nextflow generará report, timeline, trace y DAG.
- nf-core/rnaseq se utiliza como referencia de diseño, no como
  pipeline ejecutado en este proyecto.