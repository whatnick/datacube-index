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

while getopts ":u:p:b:s:i:y:d:" o; do
    case "${o}" in
        u)
            protocol=${OPTARG}
            ;;
        p)
            prefix=${OPTARG}
            ;;
        b)
            b=${OPTARG}
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
        l)
            lineage=${OPTARG}
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
first_suffix="${suffixes[0]}"
safety_arg=""

if [ "$safety" == "SAFE" ]
then
    safety_arg="--skip-check"
fi



# index new datasets
# prepare script will add new records to the database
for i in "${!prefixes[@]}"
do
    # Set suffix string
    if [ -z "${suffixes[$i]}"  ] && [ -z "${first_suffix}" ]
    then
        suffix_string=""
    elif [ -z "${suffixes[$i]}" ]
    then
        suffix_string="${first_suffix}"
    else
        suffix_string="${suffixes[$i]}"
    fi

    if [ -z "$lineage" ]
    then
        # Index 
        if [ "${protocol}" == "s3" ]
        then
            s3-find $safety_arg "s3://${b}/${prefixes[$i]}" | \
            s3-to-tar | \
            dc-index-from-tar
        elif [ "${protocol}" == "gs" ]
        then
            gs-to-tar --bucket ${b} --prefix ${prefixes[$i]}
            dc-index-from-tar --protocol "${protocol}" metadata.tar.gz
        elif [ "${protocol}" == "http" ]
        then
            # renders list as " -s item -s item ..." using $@
            set -- $ignore
            set -- "${@/#/ -s }"

            thredds-to-tar -c "${b}/${prefixes[$i]}" -t $suffix_string -w 8 $@ 
            dc-index-from-tar --protocol "${protocol}" metadata.tar.gz
        fi
    else
        # Index without lineage
        if [ "${protocol}" == "s3" ]
        then
            s3-find $safety_arg "s3://${b}/${prefixes[$i]}" | \
            s3-to-tar | \
            dc-index-from-tar --ignore-lineage
        elif [ "${protocol}" == "gs" ]
        then
            gs-to-tar --bucket ${b} --prefix ${prefixes[$i]}
            dc-index-from-tar --protocol "${protocol}" metadata.tar.gz --ignore-lineage
        elif [ "${protocol}" == "http" ]
        then
            # renders list as " -s item -s item ..." using $@
            set -- $ignore
            set -- "${@/#/ -s }"

            thredds-to-tar -c "${b}/${prefixes[$i]}" -t $suffix_string -w 8 $@ 
            dc-index-from-tar --protocol "${protocol}" metadata.tar.gz --ignore-lineage
        fi
    fi
done

# update ranges in wms database

if [ -z "$product" ]
then
    python3 /code/update_ranges.py --no-calculate-extent
else

    for i in "${!products[@]}"
    do
        python3 /code/update_ranges.py --no-calculate-extent --product "${products[$i]}"
    done
fi

#python3 /code/update_ranges.py --no-calculate-extent ${product:+"--product"} ${product:+"$product"}
