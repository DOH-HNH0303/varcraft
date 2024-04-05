#!/bin/bash

echo "sample,ani,rep,length,n" > summary.csv
cat $1 | tr '\t ' '_' | sed 's/>.*$/@&@/g' | tr -d '\n' | tr '@' '\n' | tail -n +2 | tr -d '>' | paste - - | awk '{print $1,length($2),toupper($2)}' | awk '{n = gsub(/N/,"", $3); print $1,$2,n}' | sed 's/^Consensus_//g' | sed 's/.ani_/\t/g' | sed 's/.rep_/\t/g' | sed -E 's/_threshold_[0-9]+_quality_[0-9]+/\t/g' | awk -v OFS=',' '{sub(/-/,".",$2); print $0}' >> summary.csv
