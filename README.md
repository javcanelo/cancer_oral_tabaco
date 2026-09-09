# Tabaquismo y expresión génica en carcinoma escamoso oral

## Pregunta biomédica

¿Qué diferencias de expresión génica y vías biológicas se asocian
al antecedente de tabaquismo en tejido tumoral de pacientes con
carcinoma oral de células escamosas HPV negativo?

## Objetivo

Identificar genes y vías biológicas asociados al antecedente de
tabaquismo mediante un análisis reproducible de RNA-seq.

## Diseño del proyecto

Se utilizará un enfoque híbrido:

1. FASTQ de GSE184616 para implementar y ejecutar un workflow
   Nextflow DSL2 sobre ocho muestras tumorales.
2. Conteos preprocesados de TCGA-HNSC para el análisis principal
   de expresión génica y su asociación con tabaquismo.

Las cohortes se analizarán por separado.
El límite N < 10 corresponde a las muestras biológicas
procesadas mediante Nextflow.

## Dataset para Nextflow: GSE184616

- Organismo: Homo sapiens.
- Enfermedad: carcinoma oral de células escamosas.
- Dataset completo: 15 pacientes, 15 tumores y 15 tejidos normales.
- Tecnología: bulk RNA-seq, paired-end, stranded.
- Plataforma: Illumina NovaSeq 6000.
- Preparación: RNA total con eliminación de RNA ribosomal.
- Accesión SRA del estudio: SRP338257.
- BioProject: PRJNA765370.
- Selección: ocho tumores primarios HPV negativos.
- Grupos: cuatro con antecedente de tabaquismo y cuatro nunca fumadores.
- Unidad biológica: un paciente con una muestra tumoral.

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

## Justificación de la selección

Cada grupo incluye tres tumores de lengua y uno de piso de boca.

Todos los pacientes con antecedente de tabaquismo disponibles
en la tabla revisada son hombres. Solo hay tres hombres nunca
fumadores, por lo que la selección de cuatro pacientes por grupo
incluye una mujer en el grupo nunca fumador.

Las edades medias son 37,3 años en ever_smoker y 44,8 años
en never_smoker. La selección no está completamente equilibrada
en edad y sexo.

Estas ocho muestras se utilizarán principalmente para demostrar
el funcionamiento del workflow. El análisis principal será en TCGA.

## Samplesheet

Archivo: metadata/samplesheet.csv.

Columnas:
- sample: identificador de la muestra biológica.
- run: identificador de secuenciación SRA.
- fastq_1: ruta relativa del archivo R1.
- fastq_2: ruta relativa del archivo R2.

El archivo contiene doce filas de runs correspondientes a ocho
muestras biológicas y veinticuatro archivos FASTQ previstos.

OSCC_13-P y OSCC_11-P tienen tres runs cada una.
El workflow agrupará los runs por muestra antes de cuantificar.
No se considerarán réplicas biológicas independientes.

Las rutas data/raw/<SRR>_1.fastq.gz y data/raw/<SRR>_2.fastq.gz
son las rutas planificadas para organizar las lecturas.

El workflow se ejecutará desde la raíz del proyecto.
Este samplesheet corresponde al diseño del workflow propio
y su lectura se implementará en Nextflow DSL2.

## Cohorte principal: TCGA-HNSC

Se utilizarán conteos génicos preprocesados y metadatos clínicos.

Criterios de inclusión:
- Carcinoma escamoso de cavidad oral.
- Tumor primario.
- HPV negativo documentado.
- Antecedente de tabaquismo conocido.
- Una muestra tumoral por paciente.

Grupos:
- ever_smoker: fumadores actuales y exfumadores.
- never_smoker: pacientes que nunca fumaron.

Los valores desconocidos o no informados se excluirán del contraste.
No se asumirá HPV negativo por la sola localización en cavidad oral.

### Selección preliminar

- La descarga clínica contiene 167 pacientes.
- Hay 163 con tabaquismo conocido: 115 ever_smoker y 48 never_smoker.
- Se encontraron registros explícitos de HPV para 35 pacientes.
- De ellos, 29 tienen únicamente resultados negativos en los registros revisados.
- TCGA-BB-7872 presenta resultados negativos y positivos y se excluyó
  provisionalmente por discordancia.
- Al cruzar los 29 candidatos con la información de tabaquismo,
  quedan 28 pacientes: 22 ever_smoker y 6 never_smoker.
- Un candidato no tiene una categoría conocida de tabaquismo.

La cohorte es provisional. Falta verificar el contexto y método de
las pruebas de HPV, la precisión del sitio anatómico y la correspondencia
con los archivos de expresión de tumor primario.

El desequilibrio entre grupos y el tamaño del grupo never_smoker
se considerarán limitaciones del análisis.

La selección provisional está guardada en:
metadata/tcga/derived/tcga_candidates.tsv. 

## Workflow previsto

FASTQ → FastQC → agrupación por muestra → Salmon → MultiQC.

Se evaluará trimming según el control de calidad.
Se documentarán referencias, versiones y parámetros.
Se utilizarán ambientes reproducibles.

Se generarán report, timeline, trace y DAG de Nextflow.

Diagrama de diseño: docs/workflow.md.

## Análisis principal en R

- Integración de conteos y metadatos.
- Control de calidad y filtrado de genes de baja expresión.
- Transformación adecuada para PCA y clustering.
- Expresión diferencial con DESeq2.
- Evaluación del ajuste por edad y sexo.
- Corrección por múltiples pruebas mediante FDR.
- Enriquecimiento de vías biológicas.

El contraste será ever_smoker frente a never_smoker.
Un log2 fold change positivo indicará mayor expresión
en el grupo ever_smoker.

Los resultados se interpretarán como asociaciones.
El PCA y el clustering se utilizarán para explorar la estructura
de los datos, sin asumir separación por tabaquismo.

## Comparación adicional opcional

Los conteos preprocesados de GSE184616 podrán utilizarse
para explorar concordancia de genes y vías con TCGA.

Las matrices de ambas cohortes no se combinarán directamente.
Las cuantificaciones propias y publicadas de una misma muestra
de GEO no se tratarán como observaciones independientes.

## Organización del repositorio

- metadata/geo_all_runs.csv: tabla completa de muestras y runs revisados.
- metadata/geo_selected_runs.csv: metadatos de los runs seleccionados.
- metadata/samplesheet.csv: entradas previstas para Nextflow.
- metadata/tcga/: metadatos clínicos originales descargados de GDC.
- metadata/tcga/derived/: tablas derivadas de tabaquismo, revisión de HPV y candidatos.
- docs/workflow.md: diagrama de diseño.
- workflow/: código y configuración del pipeline.
- analysis/: scripts del análisis posterior.


## Estado de desarrollo

Entrega 1: diseño del proyecto.

El workflow todavía no está implementado ni ejecutado.
La descarga de lecturas, la configuración del HPC y los comandos
de ejecución se documentarán durante la implementación.