<div align="center">

# 🧬 HG002 Short Variant Calling & Benchmarking Pipeline

**A production-ready HPC pipeline comparing Clair3 and DeepVariant on PacBio HiFi data**

[![Nextflow](https://img.shields.io/badge/Workflow-Nextflow_DSL2-23aa62?style=flat-square&logo=nextflow&logoColor=white)](https://nextflow.io/)
[![SLURM](https://img.shields.io/badge/Scheduler-SLURM-0078d4?style=flat-square&logo=linux&logoColor=white)](https://slurm.schedmd.com/)
[![Singularity](https://img.shields.io/badge/Containers-Singularity-6a0dad?style=flat-square)](https://sylabs.io/singularity/)
[![GRCh38](https://img.shields.io/badge/Reference-GRCh38-2ea44f?style=flat-square)](https://www.ncbi.nlm.nih.gov/assembly/GCF_000001405.40/)
[![GIAB](https://img.shields.io/badge/Truth%20Set-GIAB%20v4.2.1-orange?style=flat-square)](https://www.nist.gov/programs-projects/genome-bottle)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

[Overview](#overview) · [Pipeline](#pipeline) · [Nextflow](#nextflow-pipeline) · [Results](#results) · [Quick Start](#quick-start) · [Repository Layout](#repository-layout) · [References](#references)

</div>

---

## Overview

This repository implements a complete, reproducible **short variant calling and benchmarking pipeline** for HG002 PacBio HiFi sequencing data, executed on an HPC cluster using **Nextflow DSL2**, **SLURM**, and **Singularity** containers.

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

> **Note:** The full BAM was downsampled to ~25% of total reads using `bamtofastq` + `seqtk`, deliberately creating a low-coverage (~3×) scenario to stress-test both callers.

---

## Pipeline

```
PacBio HiFi BAM
      │
      ▼
┌─────────────────────┐
│   Stage 1: Prep     │  samtools sort + index + depth QC
└──────────┬──────────┘
           │
      ┌────┴────┐
      ▼         ▼
┌──────────┐ ┌─────────────┐
│  Clair3  │ │ DeepVariant │   GPU partition — run IN PARALLEL
│  (HiFi)  │ │  (PACBIO)   │   via Nextflow + SLURM + Singularity
└────┬─────┘ └──────┬──────┘
     │              │
     ▼              ▼
┌──────────────────────────┐
│     Stage 4: hap.py      │  Benchmarking vs GIAB HG002 v4.2.1
│     Benchmarking         │  chr1–22 · high-confidence BED
└──────────────────────────┘
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

## Nextflow Pipeline

The pipeline is fully implemented in **Nextflow DSL2**, enabling automatic parallelisation, SLURM job management, and Singularity containerisation through a single command.

### Pipeline structure

```
hg002-variant-benchmark/
├── main.nf                  # Main workflow — wires all processes together
├── nextflow.config          # SLURM executor + Singularity settings
├── conf/
│   └── slurm.config         # Per-process CPU/memory/GPU resource profiles
└── modules/
    ├── clair3.nf            # Clair3 variant calling process
    ├── deepvariant.nf       # DeepVariant variant calling process
    └── happy.nf             # hap.py benchmarking process
```

### Run with Nextflow

```bash
cd hg002-variant-benchmark

# Dry run — validates all file paths, submits nothing
nextflow run main.nf -profile slurm -preview

# Full run — Clair3 and DeepVariant launch in parallel automatically
nextflow run main.nf -profile slurm

# Resume after interruption — completed steps are cached
nextflow run main.nf -profile slurm -resume

# Monitor jobs
watch squeue -u $USER
```

### Key Nextflow features used

- **DSL2 modular architecture** — each tool is an independent reusable module
- **Automatic parallelisation** — Clair3 and DeepVariant submit simultaneously to SLURM
- **SLURM executor** — jobs submitted directly to the GPU partition with resource profiles
- **Singularity integration** — all processes run inside pre-built `.sif` containers
- **Resume capability** — completed stages are cached; failed runs restart from the last checkpoint
- **`publishDir`** — outputs automatically copied to `results/nextflow/`

---

## Results

Benchmarked against **GIAB HG002 v4.2.1** (GRCh38, chr1–22, PASS filter, high-confidence regions only).
Full CSV outputs are in `results_summary/`.

### Clair3

| Variant | Recall | Precision | F1 Score |
|---------|--------|-----------|----------|
| SNP | 0.5588 | 0.8320 | 0.6685 |
| INDEL | 0.4060 | 0.5122 | 0.4529 |

### DeepVariant

| Variant | Recall | Precision | F1 Score |
|---------|--------|-----------|----------|
| SNP | 0.3934 | 0.8627 | 0.5404 |
| INDEL | 0.3099 | 0.5799 | 0.4040 |

### Head-to-head comparison

| Metric | Clair3 SNP | DV SNP | Clair3 INDEL | DV INDEL |
|--------|-----------|--------|-------------|---------|
| **Recall** | **0.5588** | 0.3934 | **0.4060** | 0.3099 |
| **Precision** | 0.8320 | **0.8627** | 0.5122 | **0.5799** |
| **F1 Score** | **0.6685** | 0.5404 | **0.4529** | 0.4040 |

### Interpretation

These results reflect **~3× coverage** — far below the 15–30× recommended for reliable variant calling.

- **Clair3** achieves significantly higher recall (SNP: +16.5pp, INDEL: +9.6pp) — better at detecting variants from sparse read support due to its two-stage pileup + full-alignment architecture.
- **DeepVariant** achieves higher precision (SNP: +3.1pp, INDEL: +25.8pp) — fewer false positives but misses more true variants under low coverage due to its conservative CNN-based classifier.
- At standard depth (≥15×), both tools are expected to achieve SNP F1 > 0.98 on HiFi data.
- Low coverage primarily impacts **recall** (missed variants) rather than precision, consistent with published benchmarks.

---

## Quick Start

### Prerequisites

- HPC cluster with SLURM and Singularity (≥3.5)
- Nextflow (≥21.10): `curl -s https://get.nextflow.io | bash`
- GPU partition available for Clair3 and DeepVariant
- ~50 GB free disk space

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

# Index truth VCF
singularity exec containers/bcftools_1.17.sif bcftools index --tbi \
    HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz
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
mkdir -p containers && cd containers
singularity pull clair3_latest.sif       docker://hkubal/clair3:latest
singularity pull deepvariant_1.6.0.sif   docker://google/deepvariant:1.6.0
singularity pull hap.py_latest.sif       docker://pkrusche/hap.py:latest
singularity pull samtools_1.17.sif       docker://staphb/samtools:1.17
singularity pull bcftools_1.17.sif       docker://staphb/bcftools:1.17
cd ..
```

### 5. Update paths in config

Edit `nextflow.config` to set your actual file paths:

```groovy
params {
    bam          = "/path/to/hg002_subset.sorted.bam"
    ref          = "/path/to/GRCh38.primary_assembly.genome.fa"
    truth_vcf    = "/path/to/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz"
    truth_bed    = "/path/to/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed"
    clair3_model = "/opt/models/hifi"
    outdir       = "/path/to/results/nextflow"
}
```

Also update the GPU partition name and container paths in `conf/slurm.config`.

### 6. Run the Nextflow pipeline

```bash
# Preview first (validates everything, submits nothing)
nextflow run main.nf -profile slurm -preview

# Launch — Clair3 and DeepVariant run in parallel automatically
nextflow run main.nf -profile slurm
```

### 7. View results

```bash
cat results_summary/clair3_slurm.summary.csv
cat results_summary/deepvariant_slurm.summary.csv
```

---

## Repository Layout

```
hg002-variant-benchmark/
├── README.md                              # This file
│
├── main.nf                                # Nextflow DSL2 main workflow
├── nextflow.config                        # SLURM executor + Singularity config
├── nextflow_run.log                       # Execution log from cluster run
│
├── conf/
│   └── slurm.config                       # Per-process CPU/GPU/memory profiles
│
├── modules/
│   ├── clair3.nf                          # Clair3 variant calling process
│   ├── deepvariant.nf                     # DeepVariant variant calling process
│   └── happy.nf                           # hap.py benchmarking process
│
├── slurm/
│   ├── run_clair3.slurm                   # SLURM script: Clair3 (GPU)
│   ├── run_deepvariant.slurm              # SLURM script: DeepVariant (GPU)
│   └── run_happy_clair3.slurm             # SLURM script: hap.py benchmarking
│
├── scripts/
│   ├── clair3_command.sh                  # Clair3 Singularity command
│   ├── deepvariant_command.sh             # DeepVariant Singularity command
│   └── benchmarking_command.sh            # hap.py benchmarking command
│
└── results_summary/
    ├── clair3_slurm.summary.csv           # Clair3 benchmark summary (PASS)
    ├── clair3_slurm.extended.csv          # Clair3 extended metrics + ROC
    ├── deepvariant_slurm.summary.csv      # DeepVariant benchmark summary (PASS)
    └── deepvariant_slurm.extended.csv     # DeepVariant extended metrics + ROC
```

> **Large files excluded:** BAM files, VCF files, reference genome, and Singularity containers must be downloaded separately (see [Quick Start](#quick-start)).

---

## SLURM Job Details

| Job | Partition | CPUs | Memory | GPU |
|-----|-----------|------|--------|-----|
| Clair3 | GPU | 16 | 32 GB | 1× (T4/V100) |
| DeepVariant | GPU | 16 | 64 GB | 1× (T4/V100) |
| hap.py (Clair3) | GPU | 8 | 32 GB | — |
| hap.py (DeepVariant) | GPU | 8 | 32 GB | — |

---

## Limitations & Future Work

- **Coverage:** ~3× depth is well below the 15–30× recommended for production variant calling. Metrics reflect a deliberate stress test; both tools perform substantially better at standard depth.
- **Scope:** Only SNPs and INDELs on chr1–22 were evaluated. Structural variants and sex chromosomes are out of scope.
- **Planned improvements:**
  - Coverage stratification benchmarks (5×, 10×, 15×, 30×) to produce performance-vs-depth curves
  - Structural variant calling using pbsv or Sniffles2
  - nf-core compliance for broader community portability

---

## References

1. Poplin R et al. (2018). A universal SNP and small-indel variant caller using deep neural networks. *Nature Biotechnology*, 36, 983–987. (**DeepVariant**)
2. Zheng Z et al. (2022). Symphonizing pileup and full-alignment for deep learning-based long-read variant calling. *Nature Computational Science*, 2, 797–803. (**Clair3**)
3. Krusche P et al. (2019). Best practices for benchmarking germline small-variant calls in human genomes. *Nature Biotechnology*, 37, 555–560. (**hap.py**)
4. Zook JM et al. (2020). An open resource for accurately benchmarking small variant and reference calls. *Nature Biotechnology*, 38, 1347–1355. (**GIAB**)
5. Kurtzer GM et al. (2017). Singularity: Scientific containers for mobility of compute. *PLOS ONE*, 12(5).
6. Di Tommaso P et al. (2017). Nextflow enables reproducible computational workflows. *Nature Biotechnology*, 35, 316–319. (**Nextflow**)

---

<div align="center">

**Authors:** Pukhraj Tahir, Faiqa Zarar Noor &nbsp;|&nbsp; **Assignment #1** &nbsp;|&nbsp; **Due: 22 February 2025**

*PacBio HiFi · Clair3 · DeepVariant · GIAB · Nextflow DSL2 · SLURM · Singularity · GRCh38 · hap.py*

</div>
