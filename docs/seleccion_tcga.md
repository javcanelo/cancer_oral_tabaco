# Selección preliminar de la cohorte TCGA-HNSC

## Fuente de los datos

Los metadatos clínicos se descargaron desde el portal GDC el
9 de septiembre de 2026, después de aplicar una selección inicial
del proyecto TCGA-HNSC y localizaciones de cavidad oral.

La descarga contiene 167 pacientes únicos.

## Archivos originales

Los siguientes archivos se conservaron sin modificaciones en
`metadata/tcga/`:

- `clinical.tsv`
- `exposure.tsv`
- `family_history.tsv`
- `follow_up.tsv`
- `pathology_detail.tsv`

Las tablas derivadas se guardaron en `metadata/tcga/derived/`.

## Variables utilizadas

### Datos clínicos

Columnas de `clinical.tsv` utilizadas en esta descarga:

| Número | Variable | Uso |
|---:|---|---|
| 2 | `cases.case_id` | Identificador interno del caso |
| 10 | `cases.submitter_id` | Código del paciente TCGA |
| 11 | `demographic.age_at_index` | Edad |
| 26 | `demographic.sex_at_birth` | Sexo |
| 56 | `diagnoses.classification_of_tumor` | Clasificación del tumor |
| 68 | `diagnoses.diagnosis_is_primary_disease` | Identificación del diagnóstico principal |
| 93 | `diagnoses.icd_10_code` | Código anatómico |
| 115 | `diagnoses.morphology` | Morfología |
| 120 | `diagnoses.primary_diagnosis` | Diagnóstico histológico |
| 128 | `diagnoses.site_of_resection_or_biopsy` | Sitio de obtención |
| 134 | `diagnoses.tissue_or_organ_of_origin` | Órgano o tejido de origen |

Se consideró inicialmente el diagnóstico con
`diagnoses.diagnosis_is_primary_disease = true`.

### Tabaquismo

Columnas de `exposure.tsv`:

| Número | Variable | Uso |
|---:|---|---|
| 2 | `cases.case_id` | Unión con los demás metadatos |
| 3 | `cases.submitter_id` | Código del paciente TCGA |
| 14 | `exposures.cigarettes_per_day` | Intensidad complementaria |
| 24 | `exposures.pack_years_smoked` | Exposición acumulada complementaria |
| 32 | `exposures.tobacco_smoking_status` | Clasificación principal |

Se definieron los grupos:

- `ever_smoker`: `Current Smoker` y todas las categorías
  `Current Reformed Smoker`.
- `never_smoker`: `Lifelong Non-Smoker`.
- Sin clasificación: `'--`, `Not Reported` y `Unknown`.

Los registros ausentes adicionales no invalidaron una categoría
conocida del mismo paciente.

Se obtuvieron 163 pacientes clasificables:

- 115 `ever_smoker`.
- 48 `never_smoker`.
- 4 pacientes sin información utilizable.

No se encontraron pacientes con más de una categoría conocida
de tabaquismo.

## Construcción de la tabla de tabaquismo

```bash
mkdir -p metadata/tcga/derived

printf 'case_id\tpatient_id\tsmoking_original\tgroup\n' \
> metadata/tcga/derived/smoking.tsv

awk -F '\t' 'BEGIN {OFS="\t"}
NR > 1 && $32 == "Lifelong Non-Smoker" {
    print $2,$3,$32,"never_smoker"
}
NR > 1 && (
    $32 == "Current Smoker" ||
    $32 ~ /^Current Reformed Smoker/
) {
    print $2,$3,$32,"ever_smoker"
}
' metadata/tcga/exposure.tsv |
sort -u >> metadata/tcga/derived/smoking.tsv
```

Comprobación:

```bash
wc -l metadata/tcga/derived/smoking.tsv

tail -n +2 metadata/tcga/derived/smoking.tsv |
cut -f 4 |
sort |
uniq -c
```

Resultado:

```text
164 líneas: una cabecera y 163 pacientes
115 ever_smoker
48 never_smoker
```

## Revisión de HPV

En `follow_up.tsv` se encontraron estas columnas:

| Número | Variable |
|---:|---|
| 2 | `cases.case_id` |
| 3 | `cases.submitter_id` |
| 48 | `molecular_tests.biospecimen_type` |
| 64 | `molecular_tests.hpv_strain` |
| 66 | `molecular_tests.laboratory_test` |
| 73 | `molecular_tests.molecular_analysis_method` |
| 75 | `molecular_tests.molecular_test_id` |
| 86 | `molecular_tests.test_result` |

Se localizaron 62 filas que mencionaban
`Human Papillomavirus`, pertenecientes a 35 pacientes.

Los resultados por paciente fueron:

- 29 pacientes con resultado exclusivamente negativo.
- 1 paciente exclusivamente positivo.
- 4 pacientes con resultado desconocido.
- 1 paciente, `TCGA-BB-7872`, con resultados negativo y positivo.

El paciente `TCGA-BB-7872` se excluyó provisionalmente por
discordancia. Esta exclusión no resuelve su estado biológico.

El tipo de espécimen registrado para las 62 filas fue
`Involved Tissue, NOS`. El método fue `ISH` en 26 filas negativas;
otras 27 filas negativas no informaron el método.

## Extracción de los registros de HPV

```bash
awk 'NR == 1 || /Human Papillomavirus/' \
metadata/tcga/follow_up.tsv |
cut -f 2,3,48,64,66,73,75,86 \
> metadata/tcga/derived/hpv_tests_review.tsv

tail -n +2 metadata/tcga/derived/hpv_tests_review.tsv |
cut -f 1,2,8 |
sort -u \
> metadata/tcga/derived/hpv_patient_results.tsv
```

Selección de candidatos con resultado únicamente negativo:

```bash
awk -F '\t' '
$3 == "Negative" && $2 != "TCGA-BB-7872" {
    print $1
}
' metadata/tcga/derived/hpv_patient_results.tsv |
sort -u \
> metadata/tcga/derived/hpv_negative_candidate_ids.txt
```

## Cruce entre HPV y tabaquismo

Se copió la cabecera de la tabla de tabaquismo:

```bash
head -n 1 metadata/tcga/derived/smoking.tsv \
> metadata/tcga/derived/tcga_candidates.tsv
```

Se conservaron los pacientes presentes en ambas fuentes:

```bash
awk -F '\t' '
NR == FNR {
    ids[$1] = 1
    next
}
FNR > 1 && ($1 in ids)
' metadata/tcga/derived/hpv_negative_candidate_ids.txt \
metadata/tcga/derived/smoking.tsv \
>> metadata/tcga/derived/tcga_candidates.tsv
```

Comprobación:

```bash
tail -n +2 metadata/tcga/derived/tcga_candidates.tsv |
cut -f 4 |
sort |
uniq -c

tail -n +2 metadata/tcga/derived/tcga_candidates.tsv |
wc -l
```

Resultado provisional:

```text
28 pacientes
22 ever_smoker
6 never_smoker
```

## Limitaciones y verificaciones pendientes

La selección de 28 pacientes es provisional. Antes del análisis
de expresión se debe comprobar:

- Contexto, método y muestra asociados con cada resultado de HPV.
- Correspondencia entre diagnóstico principal y tumor de cavidad oral.
- Precisión de localizaciones anatómicas no especificadas.
- Disponibilidad de conteos de RNA-seq de tumor primario.
- Una muestra tumoral de expresión por paciente.
- Distribución de edad, sexo, sitio anatómico y consumo de alcohol.
- Relación entre los filtros mostrados en GDC y los 167 pacientes
  incluidos en la descarga clínica.

Los números de columna documentados corresponden específicamente
a los archivos descargados el 9 de septiembre de 2026.