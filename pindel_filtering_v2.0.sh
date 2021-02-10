#!/bin/bash

# Filter pindel VCF files
# Started: CC10Feb2021

# Description: Filters pindel output vcfs using bcftools (v1.11) within the Swiss Army Knife app (v4.0.1) on DNAnexus
# Requires bed file input and vcf
# Outputs filtered VCF file

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

for vcf0 in *.vcf; do
    bgzip $vcf0
done

#process vcf file 
for vcf in *.vcf.gz; do
    vcf_filename="$(echo $vcf | cut -d '.' -f1)"
    echo $vcf_filename
    echo "creating index for vcf"
    tabix -f -p vcf $vcf
    # Keep only indels that intersect with the exons of interest bed file 
    bcftools view -R $bed_file $vcf > $vcf_filename.temp1.vcf
    echo "creating restricted vcf"
    # Keep only insertions with length creater than 2, this will remove the number 1 bp false positives insertions
    bcftools view -i 'INFO/SVLEN > 2' $vcf_filename.temp1.vcf > $vcf_filename.temp2.vcf
    echo "VCF with insertions with length greater than 2 bp"
    #bgzip and create an index file for vcf 
    bgzip $vcf_filename.temp2.vcf
    echo "creating index for vcf"
    tabix -f -p vcf $vcf_filename.temp2.vcf.gz
    # Deletions are marker with a - in the pindel outputs therefore to keep deletions a seperate vcf is created keeping deletions larger than 2bp (-2)
    bcftools view -i 'INFO/SVLEN < -2' $vcf_filename.temp1.vcf > $vcf_filename.temp3.vcf
    echo "VCF with deletions with length greater than 2 bp"
    # bgzip and create an index file for vcf 
    bgzip $vcf_filename.temp3.vcf
    echo "creating index for vcf"
    tabix -f -p vcf $vcf_filename.temp3.vcf.gz
    # Concate the two vcfs (insertions and deletions) to create the a single filtered vcf
    bcftools concat -o $vcf_filename.temp4.vcf $vcf_filename.temp2.vcf.gz $vcf_filename.temp3.vcf.gz
    echo "VCFs concatenated"
    # vcf-sort will sort the vcf by chromosome and position order; Concat does not sort the vcf (adds on rows from the second vcf to the first) therefore vcf-sort 
    vcf-sort $vcf_filename.temp4.vcf > $vcf_filename.filtered.vcf
    echo "sorted VCF"
    #bgzip and create an index file for vcf
    bgzip $vcf_filename.filtered.vcf
    echo "creating index for vcf"
    tabix -f -p vcf $vcf_filename.filtered.vcf.gz
    #Remove all *temp* files
    rm *temp*
done
