# Workflow del proyecto

Workflow en Nextflow para ocho muestras tumorales
de GSE184616 y análisis posterior en R.

```mermaid
flowchart TD
    subgraph Entradas ["Entradas"]
        A["samplesheet.csv"]
        B["FASTQ paired-end: 12 runs"]
        R["Índice de referencia de Salmon"]
        T["Correspondencia transcrito-gen"]
        M["Metadatos: 8 muestras, 4 por grupo"]
    end

    subgraph NF ["Workflow propio en Nextflow DSL2"]
        C["FastQC"]
        D{"¿Aplicar trimming?"}
        E["Trimming"]
        F["Agrupación de runs por muestra"]
        G["Salmon"]
        Q[["Reporte MultiQC"]]
    end

    subgraph Analisis ["Análisis posterior en R"]
        H["tximport"]
        I["DESeq2: filtrado y normalización"]
        J["VST, PCA y clustering"]
        K["Expresión diferencial y FDR"]
        L["Enriquecimiento funcional"]
    end

    A -. "Identifica muestras y rutas" .-> B
    B -- "FASTQ originales" --> C
    B -- "FASTQ originales" --> D

    D -- "Sí: lecturas por recortar" --> E
    D -- "No: lecturas originales" --> F
    E -- "FASTQ procesados, R1 y R2" --> F

    F -- "Lecturas reunidas de cada muestra" --> G
    R -- "Secuencias de referencia indexadas" --> G

    C -. "Reportes de calidad" .-> Q
    E -. "Logs de recorte" .-> Q
    G -. "Métricas de cuantificación" .-> Q

    G -- "8 archivos quant.sf" --> H
    T -- "Relación entre transcritos y genes" --> H
    H -- "Conteos estimados y longitudes por gen" --> I
    M -- "Grupos y variables clínicas" --> I

    I -- "Datos para transformación VST" --> J
    I -- "Datos para ajustar el modelo" --> K
    K -- "Genes ordenados por estadístico" --> L
```

## Decisiones de diseño

- La necesidad de trimming se decidirá mediante revisión de calidad
  y se configurará explícitamente; FastQC no toma esa decisión.
- Los runs se agruparán manteniendo R1 y R2 correctamente asociados.
- Cada muestra biológica producirá una cuantificación.
- Si se aplica trimming, se revisará también la calidad de las lecturas procesadas.
- MultiQC integrará los reportes de las herramientas.
- tximport permitirá pasar de cuantificaciones de transcritos
  a información a nivel de gen para el análisis.
- Nextflow generará report, timeline, trace y DAG.
