<div align="center">

# 🧬 HG002 Short Variant Calling & Benchmarking Pipeline

**A production-ready HPC pipeline comparing Clair3 and DeepVariant on PacBio HiFi data**

[![SLURM](https://img.shields.io/badge/Scheduler-SLURM-0078d4?style=flat-square&logo=linux&logoColor=white)](https://slurm.schedmd.com/)
[![Singularity](https://img.shields.io/badge/Containers-Singularity-6a0dad?style=flat-square)](https://sylabs.io/singularity/)
[![GRCh38](https://img.shields.io/badge/Reference-GRCh38-2ea44f?style=flat-square)](https://www.ncbi.nlm.nih.gov/assembly/GCF_000001405.40/)
[![GIAB](https://img.shields.io/badge/Truth%20Set-GIAB%20v4.2.1-orange?style=flat-square)](https://www.nist.gov/programs-projects/genome-bottle)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

[Overview](#overview) · [Pipeline](#pipeline) · [Results](#results) · [Quick Start](#quick-start) · [Repository Layout](#repository-layout) · [References](#references)

</div>

---

## Overview

This repository implements a complete, reproducible **short variant calling and benchmarking pipeline** for HG002 PacBio HiFi sequencing data, executed on an HPC cluster using **SLURM** and **Singularity** containers.

Two state-of-the-art deep-learning variant callers are compared head-to-head:

| Caller | Model | Strategy |
|--------|-------|----------|
| **Clair3** | HiFi (pileup + full-alignment) | Maximises recall; phased output |
| **DeepVariant v1.6.0** | PACBIO (CNN image classifier) | Maximises precision; conservative calls |

All variant calls are benchmarked against the **GIAB HG002 v4.2.1** high-confidence truth set (GRCh38, chr1–22) using **hap.py**.

---

## Dataset

| Field | Value |
|-------|-------|
| **Sample** | HG002 / NA24385 (Ashkenazim son, GIAB trio) |
| **Platform** | PacBio HiFi (CCS, 2024 Q4 Vega release) |
| **Input BAM** | `hg002_subset.sorted.bam` (~4.1 GB) |
| **Mean coverage** | ~3× (verified with `samtools depth`) |
| **Reference** | GRCh38 primary assembly |
| **Truth set** | GIAB HG002 v4.2.1 — chr1–22 |
| **Source** | [downloads.pacbcloud.com/public/2024Q4/Vega/HG002/data/](https://downloads.pacbcloud.com/public/2024Q4/Vega/HG002/data/) |

> **Note:** The full BAM was downsampled to ~25% of total reads using `bamtofastq` + `seqtk`, deliberately creating a low-coverage scenario to stress-test both callers.

---

## Pipeline

```
PacBio HiFi BAM
      │
      ▼
┌─────────────────┐
│  Stage 1: Prep  │  samtools sort + index + depth QC
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌───────────┐
│ Clair3 │ │DeepVariant│   GPU partition (SLURM + Singularity)
│ (HiFi) │ │ (PACBIO)  │
└────┬───┘ └─────┬─────┘
     │           │
     ▼           ▼
┌─────────────────────┐
│  Stage 4: hap.py    │  Benchmarking vs GIAB HG002 v4.2.1
│  Benchmarking       │  chr1–22 · high-confidence BED
└─────────────────────┘
```

### Tools & Containers

| Container | Version | Purpose |
|-----------|---------|---------|
| `clair3_latest.sif` | Latest (HiFi model) | Long-read SNP & INDEL calling |
| `deepvariant_1.6.0.sif` | v1.6.0 (PACBIO) | CNN-based variant calling |
| `hap.py_latest.sif` | Latest | Truth-set benchmarking |
| `samtools_1.17.sif` | v1.17 | BAM sorting, indexing, QC |
| `bcftools_1.17.sif` | v1.17 | VCF filtering & normalisation |

---

## Results

Benchmarked against **GIAB HG002 v4.2.1** (GRCh38, chr1–22, high-confidence regions only).

### Clair3

| Variant | Recall | Precision | F1 |
|---------|--------|-----------|-----|
| SNP | 0.559 | 0.832 | 0.669 |
| INDEL | 0.406 | 0.512 | 0.453 |

### DeepVariant

| Variant | Recall | Precision | F1 |
|---------|--------|-----------|-----|
| SNP | 0.394 | 0.864 | 0.542 |
| INDEL | 0.307 | 0.763 | 0.438 |

### Interpretation

These results reflect **~3× coverage** — far below the 15–30× recommended for reliable variant calling.

- **Clair3** achieves significantly higher recall (SNP: +16.5pp, INDEL: +9.9pp) — better at detecting variants from sparse read support.
- **DeepVariant** achieves higher precision (SNP: +3.2pp, INDEL: +25.1pp) — fewer false positives but misses more true variants.
- At standard depth (≥15×), both tools are expected to achieve SNP F1 > 0.98.

---

## Quick Start

### Prerequisites

- HPC cluster with SLURM and Singularity (≥3.5)
- GPU partition available (recommended for Clair3 and DeepVariant)
- ~100 GB scratch space

### 1. Clone the repository

```bash
git clone https://github.com/pukhraj-tahir/hg002-variant-benchmark.git
cd hg002-variant-benchmark
```

### 2. Download input data

```bash
# Input BAM (PacBio HiFi HG002 — 2024Q4 Vega)
wget https://downloads.pacbcloud.com/public/2024Q4/Vega/HG002/data/

# Reference genome (GRCh38)
wget https://ftp.ensembl.org/pub/release-110/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz

# GIAB HG002 v4.2.1 truth set
wget https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/AshkenazimTrio/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz
wget https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/AshkenazimTrio/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed
```

### 3. Prepare input BAM

```bash
# Convert BAM → FASTQ, subsample to 25%, realign
bamtofastq -i hg002_full.bam -o hg002_reads.fastq.gz
seqtk sample -s42 hg002_reads.fastq.gz 0.25 > hg002_subset.fastq.gz
minimap2 -ax map-hifi GRCh38.fa hg002_subset.fastq.gz \
  | samtools sort -o hg002_subset.sorted.bam
samtools index hg002_subset.sorted.bam
```

### 4. Pull Singularity containers

```bash
singularity pull clair3_latest.sif docker://hkubal/clair3:latest
singularity pull deepvariant_1.6.0.sif docker://google/deepvariant:1.6.0
singularity pull hap.py_latest.sif docker://pkrusche/hap.py:latest
singularity pull samtools_1.17.sif docker://staphb/samtools:1.17
singularity pull bcftools_1.17.sif docker://staphb/bcftools:1.17
```

### 5. Edit paths and submit jobs

```bash
# Edit the PATHS block at the top of each script to match your cluster
nano slurm/run_clair3.slurm
nano slurm/run_deepvariant.slurm
nano slurm/run_happy.slurm

# Submit
sbatch slurm/run_clair3.slurm
sbatch slurm/run_deepvariant.slurm

# After both complete:
sbatch slurm/run_happy.slurm
```

### 6. View results

```bash
cat results_summary/clair3_benchmark.summary.csv
cat results_summary/deepvariant_benchmark.summary.csv
```

---

## Repository Layout

```
hg002-variant-benchmark/
├── README.md                         # This file
├── slurm/
│   ├── run_clair3.slurm              # SLURM job: Clair3 variant calling (GPU)
│   ├── run_deepvariant.slurm         # SLURM job: DeepVariant variant calling (GPU)
│   └── run_happy.slurm               # SLURM job: hap.py benchmarking
├── scripts/
│   ├── prepare_bam.sh                # BAM prep: sort, index, coverage check
│   ├── subsample_reads.sh            # Subsample FASTQ to target fraction
│   └── postprocess_vcf.sh            # VCF normalisation and filtering
└── results_summary/
    ├── clair3_benchmark.summary.csv  # hap.py output — Clair3
    └── deepvariant_benchmark.summary.csv  # hap.py output — DeepVariant
```

> **Large files excluded from this repo:** BAM files, VCF files, reference genome, and Singularity containers must be downloaded separately (see [Quick Start](#quick-start)).

---

## SLURM Job Details

| Job | Partition | CPUs | Memory | GPU |
|-----|-----------|------|--------|-----|
| BAM Prep | CPU | 8 | 16 GB | No |
| Clair3 | GPU | 16 | 32 GB | 1× |
| DeepVariant | GPU | 16 | 64 GB | 1× |
| hap.py | CPU | 8 | 32 GB | No |

---

## Limitations & Future Work

- **Coverage:** ~3× depth is well below the 15–30× recommended for production variant calling. Metrics reflect a deliberate stress test.
- **Nextflow:** The pipeline uses SLURM bash scripts. A Nextflow wrapper (`main.nf`) is planned for improved portability and cloud compatibility.
- **Scope:** Only SNPs and INDELs on chr1–22 are evaluated. Structural variants and sex chromosomes are out of scope.
- **Planned:** Coverage stratification benchmarks (5×, 10×, 15×, 30×) and Nextflow integration.

---

## References

1. Poplin R et al. (2018). A universal SNP and small-indel variant caller using deep neural networks. *Nature Biotechnology*, 36, 983–987. (**DeepVariant**)
2. Zheng Z et al. (2022). Symphonizing pileup and full-alignment for deep learning-based long-read variant calling. *Nature Computational Science*, 2, 797–803. (**Clair3**)
3. Krusche P et al. (2019). Best practices for benchmarking germline small-variant calls in human genomes. *Nature Biotechnology*, 37, 555–560. (**hap.py**)
4. Zook JM et al. (2020). An open resource for accurately benchmarking small variant and reference calls. *Nature Biotechnology*, 38, 1347–1355. (**GIAB**)
5. Kurtzer GM et al. (2017). Singularity: Scientific containers for mobility of compute. *PLOS ONE*, 12(5).

---

<div align="center">

**Author:** Pukhraj Tahir, Faiqa Zarar Noor &nbsp;|&nbsp; **Assignment #1** &nbsp;|&nbsp; **Due: 22 February 2025**

*PacBio HiFi · Clair3 · DeepVariant · GIAB · SLURM · Singularity · GRCh38 · hap.py*

</div>
