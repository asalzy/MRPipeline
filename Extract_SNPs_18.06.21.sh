#!/bin/bash
#Get location of QC Data, snp_list and out_directory
#from PARAMS file and other default arguments
source PARAMS

#Default values for arguments
#by default the output produced is a genotype and the name of the
#output is "extracted_snps"
output_name=extracted_snps

function Help () {
        # Display Help
        echo "The extractSNP program symplifies the extraction of SNPs from UKB data. SNPs can be extracted as .gen or .bgen files."
        echo
        echo "Syntax: extractSNP <options>"
        echo "options:"
        echo "-s <a>:     (Optional) Path of SNP list to operate on. The SNP list needs to be a text file with one SNP ID per line. Including this argument will override any default SNP list defined in the PARAMS file."
        echo 
	echo "-h:         Print this Help."
        echo 
	echo "-b:         Specify that extractSNP should output extracted SNPs in a .bgen format. The user must select either the -b flag or the -g flag (or both)."
        echo 
	echo "-g:         Specify that extractSNP should output extracted SNPs in a .gen format. The user must select either the -b flag or the -g flag (or both)."
        echo 
	echo "-o <a>:     (Optional) Path to output directory. Including this argument will override any default defined in the PARAMS file."
        echo
	echo "-n <a>:     (Optional) name for output file. Including this argument will override any default defined in the PARAMS file."
        echo
}


#Get arguments for function
#Arguments include -s for location of snplist file, b for bgen output, g
#for gen output, -o for output directory, -n for name of output


while getopts "s:bgho:n:" flag
do

        case "${flag}" in
		h) #Display help 
			Help
			exit;; 
                s) snp_list=${OPTARG} #enter snplist location
                        ;;
                b) bgen=1 #output bgen file
                        ;;
                g) gen=1 #output gen file
                        ;;
                o) out_dir=${OPTARG} #set output directory
                        ;;
                n) output_name=${OPTARG} #set file name
                        ;;
                \?) echo "ERROR: Invalid option: -$OPTARG"
                        echo "use the -h flag to see the help page"
			exit 1
                        ;;
                :) echo "ERROR: Option -$OPTARG requires an argument."
                        echo "use the -h flag to see the help page"
			exit 1
                        ;;

                esac

done


#Make output directory if required. Doesnt thow error if not present
mkdir -p $out_dir

#If asking for genotype output
if [ $gen = 1 ]; then
        echo "Outputting as gen file..."
        #Loop through chomosomes in QC data
        for i in {1..22}; do
                /shared/ucl/apps/bgen/1.1.4/bin/bgenix \
                -g ${UKB_QC}/C${i}_ukbb_v3_eur_indiv_variant_qc.bgen \
                -incl-rsids $snp_list | \

                #pipe to qctool to convert to gen
                /shared/ucl/apps/qctool/ba5eaa44a62f/bin/qctool_v2.0.1 -g - -filetype bgen \
                -og ${out_dir}/CHR${i}_extracted_snps.gen

                #concatenate gen files into merged file
                if [ -f ${out_dir}/CHR${i}_extracted_snps.gen ] ; then
                        cat ${out_dir}/CHR${i}_extracted_snps.gen >> ${out_dir}/extracted_SNPs_plus_col.gen
                        awk '{$2=""; print $0}' ${out_dir}/extracted_SNPs_plus_col.gen >> ${out_dir}/${output_name}.gen

                #Remove irrelevant files
                rm ${out_dir}/extracted_SNPs_plus_col.gen
                rm ${out_dir}/CHR${i}_extracted_snps.gen

                fi
        done
fi

if [ $bgen = 1 ]; then 
        echo "Outputting as bgen file..."
        #Loop extracting SNPs from SNP list as bgen 
        for i in {1..22}; do 
                echo "Extracting SNPs from chromosome ${i}..."
                #Extract the SNPs as bgen 
                /shared/ucl/apps/bgen/1.1.4/bin/bgenix \
                -g ${UKB_QC}/C${i}_ukbb_v3_eur_indiv_variant_qc.bgen \
                -incl-rsids $snp_list > ${out_dir}/CHR${i}_extracted_snps.bgen
                
                
        done
        
        #Concatinate Bgen files 
        echo "Concatinating bgen files into single output..."
        /shared/ucl/apps/bgen/1.1.4/bin/cat-bgen \
        -clobber -g ${out_dir}/CHR{1..22}_extracted_snps.bgen \
        -og ${out_dir}/${output_name}.bgen
        
        #Remove intermediate files 
        echo "Removing intermediate files..."
        rm ${out_dir}/CHR{1..22}_extracted_snps.bgen
        
fi 
