#!/bin/bash

# Filter pindel VCF files
# Started: CC10Feb2021

# Description: Filters pindel output vcfs using bcftools (v1.11) within the Swiss Army Knife app (v4.0.1) on DNAnexus
# Inputs: .bed file defining target regions and .vcf.gz file(s) containing variants to filter
# Outputs: filtered .vcf.gz file and associated .tbi file

# Reference(s): 
# https://platform.dnanexus.com/app/swiss-army-knife
# https://github.com/samtools/bcftools 

# Start message
echo "Filter pindel VCF file"
date
echo ""

#get BED file
bed_file=*.bed 
echo $bed_file

# Compress vcf file inputs
for vcf in *.vcf; do
    bgzip $vcf
done

# Process vcf files 
for vcf in *.vcf.gz; do
    echo $vcf_basename
    vcf_basename="$(echo $vcf | cut -d '.' -f1)"
    echo "Indexing input vcf"
    tabix -f -p vcf $vcf
    # Keep only indels that intersect with the exons of interest bed file 
    echo "Creating restricted vcf"
    bcftools view -R $bed_file $vcf > $vcf_basename.temp1.vcf
    # Keep only insertions with length >= 3bp and deletion <= -3
 	bcftools view -i 'INFO/SVLEN > 2 || INFO/SVLEN < -2' $vcf_basename.temp1.vcf > $vcf_basename.filtered.vcf
    #bgzip and create an index file for vcf
    bgzip $vcf_basename.filtered.vcf
    echo "Indexing sorted concatenated vcf"
    tabix -f -p vcf $vcf_basename.filtered.vcf.gz
done

# Remove temp and input vcfs to avoid including in output
echo "Removing temp and input vcf files"
rm *temp*
rm *pindel*