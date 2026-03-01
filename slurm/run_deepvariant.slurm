#!/bin/bash
#SBATCH --job-name=deepvariant
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=logs/deepvariant.out
#SBATCH --error=logs/deepvariant.err

module purge

export TMPDIR=/hdd4/sines/specialtopicsinbioinformatics/pukhraj.sines/hg002_variant_pipeline/tmp
mkdir -p $TMPDIR

echo "Starting DeepVariant..."

singularity exec --env TMPDIR=$TMPDIR containers/deepvariant_1.6.0.sif \
/opt/deepvariant/bin/run_deepvariant \
  --model_type=PACBIO \
  --ref=data/GRCh38.primary_assembly.genome.fa \
  --reads=data/hg002_subset.sorted.bam \
  --output_vcf=results/deepvariant.vcf.gz \
  --num_shards=8

echo "DeepVariant finished."
