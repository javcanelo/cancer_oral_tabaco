# Tabaquismo y expresión génica en carcinoma oral de células escamosas

## Pregunta y objetivo

¿Qué diferencias de expresión génica y vías biológicas se asocian
al antecedente de tabaquismo en tumores de carcinoma escamoso
oral HPV negativo?

Se explorará esta asociación mediante un workflow reproducible
de RNA-seq y análisis posterior en R.

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
- `metadata/samplesheet.csv`: columnas `sample,run,fastq_1,fastq_2`;
  doce filas de runs y veinticuatro FASTQ previstos.
- `metadata/sample_metadata.csv`: una fila por muestra biológica,
  con grupo, edad, sexo, sitio anatómico y HPV.

Los FASTQ se organizarán en `data/raw/`. Sus rutas en el samplesheet
son planificadas; la descarga está pendiente. 

## Workflow previsto

FASTQ → FastQC → trimming opcional → agrupación de runs por muestra → Salmon → cuantificación de transcritos → MultiQC.

Diagrama: [docs/workflow.md](docs/workflow.md).

## Análisis e interpretación

- Filtrado de genes con baja expresión y normalización con DESeq2.
- VST para PCA y clustering.
- Expresión diferencial: ever_smoker frente a never_smoker.
- Corrección por múltiples pruebas: FDR < 0,05.
- Enriquecimiento funcional con conjuntos Hallmark.

El modelo inicial será `~ group`; se evaluará sensibilidad al ajuste
por edad. Un log2 fold change positivo indicará mayor expresión
en ever_smoker.

El análisis será exploratorio. Cuatro pacientes por grupo y el
desequilibrio de edad y sexo limitan la potencia y el control de
confusión. Los resultados se interpretarán como asociaciones.

## Organización y estado

- `metadata/`: identificación de muestras y archivos de entrada.
- `docs/`: documentación y diagrama.
- `workflow/`: código Nextflow y configuración.
- `analysis/`: scripts de R.

Entrega 1: diseño del proyecto. La implementación, descarga de FASTQ,
configuración del HPC y ejecución están pendientes.

Los productos finales incluirán el pipeline, reportes, matriz génica,
análisis en R, informe reproducible en Quarto y presentación.