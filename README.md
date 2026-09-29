# Tabaquismo y expresión génica en carcinoma oral de células escamosas

## Entrega 2

La ejecución documentada procesó subconjunto de las 8 muestras y completó 45 tareas sin errores, generando 8 cuantificaciones y un reporte integrado de MultiQC.

### Informe

- [Descargar informe de Entrega 2 en PDF](https://github.com/javcanelo/cancer_oral_tabaco/raw/refs/heads/master/docs/informes_entregas/entrega_2.pdf)
- [Fuente del informe en Quarto](docs/informes_entregas/entrega_2.qmd)
- [Diagrama del workflow](docs/informes_entregas/figuras/entrega_2/figura7.png)

### Evidencia de ejecución (28 de septiembre de 2026)

- [Carpeta completa de evidencia](docs/evidencia_entrega_2/20260928_121044/)
- [Trace: estado y recursos de las 45 tareas](docs/evidencia_entrega_2/20260928_121044/nextflow/trace.tsv)
- [Report: resumen de ejecución de Nextflow](docs/evidencia_entrega_2/20260928_121044/nextflow/report.html)
- [Timeline: distribución temporal de las tareas](docs/evidencia_entrega_2/20260928_121044/nextflow/timeline.html)
- [MultiQC: reporte integrado](docs/evidencia_entrega_2/20260928_121044/multiqc/multiqc_report.html)
- [Resumen de cuantificación por muestra](docs/evidencia_entrega_2/20260928_121044/resumen_entrega2/resumen_muestras.csv)
- [Samplesheet utilizado en la ejecución](docs/evidencia_entrega_2/20260928_121044/samplesheet.csv)
- [Versiones utilizadas](docs/evidencia_entrega_2/20260928_121044/versiones.txt)

### Implementación y reproducción

- [Workflow principal de Nextflow](workflow/main.nf)
- [Módulos del pipeline](workflow/modules/)
- [Configuración](nextflow.config)
- [Ambiente de software](environment.yml)
- [Script de ejecución](scripts/ejecutar_pipeline.sh)
- [Samplesheet de la prueba integrada](metadata/samplesheet_test_all.csv)

Las instrucciones de ejecución se encuentran más abajo en este README.

## Pregunta y objetivo

¿Qué diferencias de expresión génica y vías biológicas se asocian
al antecedente de tabaquismo en tumores de carcinoma escamoso
oral HPV negativo?

Se explorará esta asociación mediante un workflow de RNA-seq y análisis posterior en R.

## Datos y diseño

- Dataset: GSE184616; Homo sapiens.
- Tecnología: bulk RNA-seq, paired-end, stranded; Illumina NovaSeq 6000.
- Fuente de lecturas: SRA, estudio SRP338257; BioProject PRJNA765370.
- Selección: ocho tumores primarios informados como HPV negativos.
- Comparación: cuatro ever_smoker y cuatro never_smoker.
- Cada grupo incluye tres tumores de lengua y uno de piso de boca.
- Los tejidos normales se excluyen.

Las mismas ocho muestras se utilizarán para el procesamiento y el
análisis biológico.

## Muestras seleccionadas

| Muestra | Grupo | Edad | Sexo | Sitio | Runs |
|---|---|---:|---|---|---:|
| OSCC_4-P | ever_smoker | 48 | Masculino | Piso de boca | 1 |
| OSCC_5-P | ever_smoker | 22 | Masculino | Lengua | 1 |
| OSCC_13-P | ever_smoker | 37 | Masculino | Lengua | 3 |
| OSCC_16-P | ever_smoker | 42 | Masculino | Lengua | 1 |
| OSCC_1-P | never_smoker | 50 | Masculino | Lengua | 1 |
| OSCC_2-P | never_smoker | 33 | Masculino | Lengua | 1 |
| OSCC_10-P | never_smoker | 46 | Masculino | Lengua | 1 |
| OSCC_11-P | never_smoker | 50 | Femenino | Piso de boca | 3 |

## Entradas

- `metadata/geo_selected_runs.csv`: identificación y metadatos de los runs.
- `metadata/samplesheet.csv`: entradas previstas para el procesameinto completo; contiene las columnas `sample,run,fastq_1,fastq_2`.
- `metadata/sample_metadata.csv`: una fila por muestra biológica,
  con grupo, edad, sexo, sitio anatómico y HPV.
- `metadata/samplesheet_test.csv`: entrada de la prueba piloto, correspondiente a OSCC_4-P.
- `metadata/samplesheet_test_all.csv`: entradas de la prueba integradaa, correspondiente a los 12 runs de las 8 muestras.

Los subconjuntos de prueba están disponibles localmente en `data/test/` y `data/test_multirun/`. Se utilizaron los primeros 100.000 spots de cada run, equivalentes a 100.000 pares de lecturas por run.

Los FASTQ se organizarán en `data/raw/`. Sus rutas en el `metadata/samplesheet.csv` son planificadas; la descarga completa está pendiente. 

## Workflow implementado

El pipeline está implementado en Nextflow DSL2:

FASTQ → FastQC → trimming opcional → agrupación de runs por muestra → Salmon → cuantificación de transcritos → MultiQC.

    1. FastQC evalúua los FASTQ originales por run.
    2. fastp recorta adaptadores y colas polyG y filtra las lecturas.
    3. FastQC evalúa los FASTQ procesados.
    4. Los runs se agrupan por muestra, manteniendo asociados R1 y R2.
    5. Salmon genera una cuantificación de transcritos por muestra.
    6. MultiQC integra los reportes de FastQC, fastp y Salmon.

FastQC inicial y fastp reciben las lecturas originales y pueden ejecutarse en paralelo. El procesamiento con fastp se aplica a todos los runs de la configuración probada.

OSCC_11-P y OSCC_13-P tienen 3 runs cada una. Estos se entregan conjuntamente a Salmon para obtener una única cuantificación por muestra.

Diagrama: [docs/workflow.md](docs/workflow.md).

## Ambiente y ejecución

El pipeline se ejecuta en Linux/WSL con el ambiente micromamba `oscc_rnaseq` y el perfil `local`, sin contenedores. El ambiente está registrado en `environment.yml`.

| Herramienta | Versión utilizada |
|---|---|
| Nextflow | 26.04.6 1|
| FastQC | 0.12.1 |
| fastp | 1.3.7 |
| Salmon | 2.7.0 |
| MultiQC | 1.35 |

Los comandos se ejecutan desde la raíz del proyecto, con el ambiente activado:

```bash 
micromamba activate oscc_rnaseq
```

Prueba piloto sobre OSCC_4-P:

```bash
bash scripts/ejecutar_pipeline.sh metadata/samplesheet_test.csv
```

Prueba integrada sobre los 12 runs:

```bash
bash scripts/ejecutar_pipeline.sh metadata/samplesheet_test_all.csv
```

Antes de ejecutar, deben estar disponibles los FASTQ indicados en el samplesheet y el índice de Salmon en `reference/salmon_gencode_v50/`.

El lanzador genera una carpeta `results/pipeline/<fecha_hora>/`, guarda el samplesheet y las versiones utilizadas y solicita los reportres de ejecución de Nextflow.

## Resultados de la prubea

La ejecución documentada en la entrega 2 se encuentra en `results/pipeline/20260928_121044/`.

Ejecutada localmente, procesó los primeros 100.000 spots de cada uno de los 12 runs y completó 45 tareas en 22 min 48 s. Generó 8 cuantificaciones, una por muestra, y 1 reporte integrado de MultiQC.

Se comprobó que los fragmentos procesados por Salmon coincidieran con la suma de pares conservados por fastp para cada muestra.

Cada ejecución organiza sus salidas en:

- `fastqc_raw/`: reportes de las lecturas originales.
- `fastp/`: FASTQ procesdos y reportes de filtrado.
- `fastqc_trimmed/`: reportes de las lecturas procesadas.
- `salmon/`: cuantificaciones y métricas por muestra.
- `multiqc/`: reporte integrado y datos asociados.
- `reportes/`: samplesheet, versiones, report, timeline y trace.

Las pruebas validan el funcionamiento técnico del pipeline con subconjuntos. No representan el procesamiento completo ni permiten establecer diferencias biológicas entre los grupos.

## Evidencia de la ejecución

Se incluye una copia de los reportes de la ejecución del 28 de septiembre de 2026 en `docs/evidencia_entrega_2/20260928_121044/`.

La carpeta contiene los reportes `report.html`, `timeline.html` y `trace.tsv` de Nextflow, el samplesheet ejecutado, las versiones del software, el reporte MultiQC y las tablas de resumen.

## Análisis e interpretación

Esta etapa está pendiente y se realizará después del procesamiento completo.

- Importación de las cuantificaciones con tximport y agregación de transcritos a genes utilizando una correspondencia compatible con la referencia de Salmon.
- Filtrado de genes con baja expresión y normalización con DESeq2.
- VST para PCA y clustering.
- Expresión diferencial: ever_smoker frente a never_smoker.
- Corrección por múltiples pruebas: FDR < 0,05.
- Enriquecimiento funcional con conjuntos Hallmark.

El modelo inicial será `~ group`. Un log2 fold change positivo indicará mayor expresión en ever_smoker.

El análisis será exploratorio. Cuatro pacientes por grupo y el
desequilibrio de edad y sexo limitan la potencia y el control de
confusión. Los resultados se interpretarán como asociaciones.

## Organización y estado

- `metadata/`: metadatos y samplesheets.
- `docs/`: documentación, diagrama e informes de entrega.
- `workflow/`: flujo principal, subworkflow y módulos de Nextflow.
- `nextflow.config`: parámetros y configuración de ejecución.
- `environment.yml`: ambiente de software.
- `scripts/`: descarga de subconjuntos, preparación de referencia, ejecución y resumen de resultados.
- `analysis/`: scripts de R.
- `data/`: lecturas locales de prueba y ubicación prevista de los datos completos.
- `reference/`: FASTA e índice de Salmon.
- `results/`: salidas organizadas por ejecución.
- `work/`: archivos intermedios de Nextflow.


Entrega 1: diseño del proyecto. 

Entrega 2: pipeline funcional.
