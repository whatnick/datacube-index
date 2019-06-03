#!/bin/bash
# Index new datasets and update ranges for WMS
# should be run after archiving old datasets so that
# ranges for WMS are correct
# environment variables:
# Usage: -p prefix(es) for search. If multiple use space seperated list enclosed in quotes
#        -b bucket containing data
#        -s suffix for search (optional). If multiple use space separated list enclosed in quotes
#                                         If multiple must be same length as prefix list,
#                                         if only one provided, suffix will be applied to ALL prefixes
#        -y UNSAFE: If set script will use unsafe YAML reading. Only set if you fully trust source
#        -d product to update in database (optional)
# e.g. ./update_ranges -b dea-public-data -p "L2/sentinel-2-nrt/S2MSIARD/2018 L2/sentinel-2-nrt/2017"

usage() { echo "Usage: $0 -u <protocol> -p <prefix> -b <bucket> [-s <suffix>] [-i <ignore>] [-y UNSAFE]" 1>&2; exit 1; }

while getopts ":u:p:b:s:i:y:d:m:l:e:n:" o; do
    case "${o}" in
        u)
            protocol=${OPTARG}
            ;;
        b)
            b=${OPTARG}
            ;;
        p)
            prefix=${OPTARG}
            ;;
        s)
            suffix=${OPTARG}
            ;;
        y)
            safety=${OPTARG}
            ;;
        i)
            ignore=${OPTARG}
            ;;
        d)
            product=${OPTARG}
            ;;
        m) 
            multiproduct=${OPTARG}
            ;;
        l)
            ignorelineage=${OPTARG}
            ;;
        e)
            exclude=${OPTARG}
            ;;
	n)
	    numberdays=${OPTARG}
	    ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${prefix}" ] || [ -z "${b}" ]; then
    usage
fi

IFS=' ' read -r -a prefixes <<< "$prefix"
IFS=' ' read -r -a suffixes <<< "$suffix"
IFS=' ' read -r -a products <<< "$product"
IFS=' ' read -r -a multiproducts <<< "$multiproduct"
first_suffix="${suffixes[0]}"
safety_arg=""

current_date=$(date +%F)

# index new datasets
for i in "${!prefixes[@]}"; do

    # AWS S3 Bucket
    if [ "${protocol}" == "s3" ]; then

        if [ "$safety" == "SAFE" ]; then
            safety_arg="--skip-check"
        fi

        s3-find $safety_arg "s3://${b}/${prefixes[$i]}" | \
        s3-to-tar | \
        dc-index-from-tar ${exclude:+"--exclude-product"} ${exclude:+"$exclude"} ${ignorelineage:+"--ignore-lineage"}

    # Google Storage Bucket
    elif [ "${protocol}" == "gs" ]; then
        gs-to-tar --bucket ${b} --prefix ${prefixes[$i]}
        dc-index-from-tar --protocol "${protocol}" metadata.tar.gz ${exclude:+"--exclude-product"} ${exclude:+"$exclude"} ${ignorelineage:+"--ignore-lineage"}
    
    # NCI thredds server
    elif [ "${protocol}" == "http" ]; then
        # Set suffix string
        if [ -z "${suffixes[$i]}"  ] && [ -z "${first_suffix}" ]; then
            suffix_string=""
        elif [ -z "${suffixes[$i]}" ]; then
            suffix_string="${first_suffix}"
        else
            suffix_string="${suffixes[$i]}"
        fi
        #Check if the number of days is empty string otherwise set default to 30 days
	if [ -z "${numberdays}" ]; then
	    number=30
	else
	    number=$numberdays
	fi

        # renders list as " -s item -s item ..." using $@
        set -- $ignore
        set -- "${@/#/ -s }"
	if [ -n "${numberdays}" ]; then
	   number=$numberdays
	   until [ $number -lt 1 ]
	   do
	       processing_date=$(date -d "$current_date - $number days" +%F)
	       thredds-to-tar -c "${b}/${prefixes[$i]}/${processing_date}" -t $suffix_string -w 8 $@
               dc-index-from-tar --protocol "${protocol}" metadata.tar.gz ${exclude:+"--exclude-product"} ${exclude:+"$exclude"} ${ignorelineage:+"--ignore-lineage"}
  	       ((number--))
	   done
	else
           thredds-to-tar -c "${b}/${prefixes[$i]}" -t $suffix_string -w 8 $@ 
           dc-index-from-tar --protocol "${protocol}" metadata.tar.gz ${exclude:+"--exclude-product"} ${exclude:+"$exclude"} ${ignorelineage:+"--ignore-lineage"}
	fi
    fi
done

# update ranges in wms database
if [ -z "$product" ]; then
    python3 /code/update_ranges.py --no-calculate-extent
else
    for i in "${!products[@]}"; do
        python3 /code/update_ranges.py --no-calculate-extent --product "${products[$i]}"
    done
fi
# if multiproducts are set, update them too
if [ -n "$multiproduct" ]; then
    for i in "${!multiproducts[@]}"; do
        python3 /code/update_ranges.py --no-calculate-extent --multiproduct "${multiproducts[$i]}"
    done
fi
