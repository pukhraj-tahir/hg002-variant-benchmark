singularity exec containers/clair3_latest.sif run_clair3.sh \
--bam_fn=data/hg002_subset.sorted.bam \
--ref_fn=data/GRCh38.primary_assembly.genome.fa \
--threads=8 \
--platform=hifi \
--model_path=/opt/models/hifi \
--output=results/clair3
