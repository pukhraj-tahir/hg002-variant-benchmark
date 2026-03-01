# HG002 Variant Calling Benchmark on HPC

## Overview

This project implements a complete variant calling and benchmarking pipeline on an HPC cluster using:

- SLURM workload manager
- Singularity containers
- Clair3 (HiFi model)
- DeepVariant (v1.6.0)
- hap.py benchmarking toolkit
- GIAB HG002 v4.2.1 truth set (GRCh38)

The objective was to compare Clair3 and DeepVariant performance under low coverage (~3X) conditions using a subset of HG002 PacBio HiFi data.

---

## Dataset

Sample: HG002 (NA24385)

Reference Genome:
GRCh38.primary_assembly.genome.fa

Input BAM:
hg002_subset.sorted.bam (4.1 GB)

Average Coverage:
~3X (computed using samtools depth)

Truth Set:
GIAB HG002 v4.2.1 (GRCh38, chromosomes 1–22)

---

## Pipeline Structure

1. Input BAM (PacBio HiFi)
2. Variant Calling:
   - Clair3 (HiFi model)
   - DeepVariant (PACBIO model)
3. Output VCF generation
4. Benchmarking using hap.py
5. Performance metric comparison

All jobs were executed on the GPU partition using SLURM.

---

## SLURM Execution

Example job submission:
sbatch run_clair3.slurm
sbatch run_deepvariant.slurm


All SLURM scripts are available in the `slurm/` directory.

---

## Containers Used

- clair3_latest.sif
- deepvariant_1.6.0.sif
- hap.py_latest.sif
- samtools_1.17.sif
- bcftools_1.17.sif

---

## Benchmark Results

### Clair3 Performance (~3X coverage)

| Variant | Recall | Precision | F1 |
|----------|--------|-----------|------|
| SNP      | 0.559  | 0.832     | 0.669 |
| INDEL    | 0.406  | 0.512     | 0.453 |

---

### DeepVariant Performance (~3X coverage)

| Variant | Recall | Precision | F1 |
|----------|--------|-----------|------|
| SNP      | 0.394  | 0.864     | 0.542 |
| INDEL    | 0.307  | 0.763     | 0.438 |

---

## Interpretation

Due to low sequencing depth (~3X):

- Recall is significantly reduced for both tools.
- DeepVariant maintains higher precision.
- Clair3 demonstrates improved recall compared to DeepVariant.
- Low coverage impacts sensitivity more than precision.

This highlights the importance of sequencing depth in variant detection performance.

---

## Reproducibility

All commands used are documented in the `scripts/` directory.

All SLURM submission files are provided in the `slurm/` directory.

Large files (BAM, VCF, containers) are intentionally excluded from this repository.
