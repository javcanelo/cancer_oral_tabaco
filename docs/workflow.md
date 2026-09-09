# Diagrama del proyecto

```mermaid
flowchart TD
    A["GEO: 8 tumores, 12 runs"] --> B["FASTQ paired-end"]
    B --> C["FastQC por run"]
    B --> D["Agrupar lecturas por muestra"]
    D --> E["Salmon: cuantificación por muestra"]
    C --> F["MultiQC"]
    E --> F
    E --> G["Cuantificaciones de 8 muestras"]

    H["TCGA-HNSC: conteos y metadatos"] --> I["Seleccionar OSCC HPV negativo"]
    I --> J["Definir grupos de tabaquismo"]
    J --> K["QC y filtrado en R"]
    K --> L["Transformación: PCA y clustering"]
    K --> M["DESeq2: expresión diferencial"]
    M --> N["FDR y enriquecimiento de vías"]
```

## Implementación prevista

- El procesamiento de FASTQ se implementará en Nextflow DSL2.
- Se evaluará trimming según los resultados de calidad.
- Los runs de una misma muestra se agruparán para cuantificarla.
- Se usarán ambientes reproducibles y versiones documentadas.
- Nextflow generará report, timeline, trace y DAG.
- El análisis principal utilizará los datos preprocesados de TCGA.
- La comparación con conteos publicados de GEO será opcional
  y se realizará mediante análisis separados.