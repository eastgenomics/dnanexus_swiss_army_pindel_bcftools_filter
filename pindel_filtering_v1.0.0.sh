#!/bin/bash

# Filter pindel VCF files
# Started: CC10Feb2021

# Description: Filters pindel output vcfs using bcftools (v1.11) within the Swiss Army Knife app (v4.0.1) on DNAnexus
# Inputs: .bed file defining target regions and .vcf file(s) containing variants to filter
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

for vcf in *.vcf; do
    bgzip $vcf
done

# Process vcf files 
for vcf in *.vcf.gz; do
    vcf_basename="$(echo $vcf | cut -d '.' -f1)"
    echo $vcf_basename
    echo "Indexing input vcf"
    tabix -f -p vcf $vcf
    # Keep only indels that intersect with the exons of interest bed file 
    echo "Creating restricted vcf"
    bcftools view -R $bed_file $vcf > $vcf_basename.temp1.vcf
    # Keep only insertions with length greater than 2. This will remove the 1 bp false positive insertions
    echo "Creating VCF with insertions with length greater than 2 bp"
    bcftools view -i 'INFO/SVLEN > 2' $vcf_basename.temp1.vcf > $vcf_basename.temp2.vcf
    #bgzip and create an index file for vcf 
    bgzip $vcf_basename.temp2.vcf
    echo "Indexing insertion vcf"
    tabix -f -p vcf $vcf_basename.temp2.vcf.gz
    # Deletions have negative SVLEN in pindel outputs therefore to keep deletions a separate vcf is created containing deletions larger than 2bp (-2)
    echo "Creating VCF with deletions with length greater than 2 bp"
    bcftools view -i 'INFO/SVLEN < -2' $vcf_basename.temp1.vcf > $vcf_basename.temp3.vcf
    # bgzip and create an index file for vcf 
    bgzip $vcf_basename.temp3.vcf
    echo "Indexing deletion vcf"
    tabix -f -p vcf $vcf_basename.temp3.vcf.gz
    # Concatenate the two vcfs (insertions and deletions) to create the a single filtered vcf
    echo "Concatenating insertion and deletion vcfs"
    bcftools concat -o $vcf_basename.temp4.vcf $vcf_basename.temp2.vcf.gz $vcf_basename.temp3.vcf.gz
    # vcf-sort will sort the vcf by chromosome and position order; Concat does not sort the vcf (adds on rows from the second vcf to the first) therefore vcf-sort
    echo "Sorting concatenated vcf"
    vcf-sort $vcf_basename.temp4.vcf > $vcf_basename.filtered.vcf
    #bgzip and create an index file for vcf
    bgzip $vcf_basename.filtered.vcf
    echo "Indexing sorted concatenated vcf"
    tabix -f -p vcf $vcf_basename.filtered.vcf.gz
done

# Remove temp and input vcfs to avoid including in output
echo "Removing temp and input vcf files"
rm *temp*
rm *pindel*
