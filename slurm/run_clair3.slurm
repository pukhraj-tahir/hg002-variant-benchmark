#!/bin/bash
#SBATCH --job-name=clair3
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=40G
#SBATCH --time=08:00:00
#SBATCH --output=logs/clair3.out
#SBATCH --error=logs/clair3.err

echo "Starting Clair3 variant calling..."
date

singularity exec containers/clair3_latest.sif \
run_clair3.sh \
--bam_fn=data/hg002_subset.sorted.bam \
--ref_fn=data/GRCh38.primary_assembly.genome.fa \
--threads=8 \
--platform=hifi \
--model_path=/opt/models/hifi \
--output=results/clair3

echo "Clair3 finished."
date
