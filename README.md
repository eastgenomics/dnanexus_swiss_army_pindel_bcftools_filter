# dnanexus_swiss_army_pindel_bcftools_filter
This repository contains the commands executed by the swiss army knife app (v4.0.1) to filter the pindel output VCF files 

## Input
The input files for this app includes a bash script(pindel_filtering_v*.sh) and vcfs produced by pindel.

The app's "command line" input is used to execute the above bash script. This command is recorded in command_line_input.sh

## How the app works
- creates a gz and index for VCF (bgzip and tabix)
- keeps indels only in exons of interest (bcftools view -i)
- keeps insertions only if the length is larger than 2bp (bcftools view -i 'INFO/SVLEN > 2')
- keeps deletions only if the length is larger than 2bp (bcftools view -i 'INFO/SVLEN < -2')
- concats the two vcfs (insertions and deletions) to generate a single filtered indel (bcftools concat)
- sorts the vcf by ascending chromosomal position (vcf-sort -c)

## Output
Filtered VCFs have a suffix of filtered.vcf.gz. The final filtered VCF is a compressed vcf (.vcf.gz).
