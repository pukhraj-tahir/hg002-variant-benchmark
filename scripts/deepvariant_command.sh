time /opt/deepvariant/bin/run_deepvariant \
--model_type=PACBIO \
--ref=data/GRCh38.primary_assembly.genome.fa \
--reads=data/hg002_subset.sorted.bam \
--output_vcf=results/deepvariant.vcf.gz \
--num_shards=16
