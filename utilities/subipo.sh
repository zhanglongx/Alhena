find ~/Alhena/database -name '*.csv' -exec awk '/^201[01234]/ {b_found=1}; END{if(!b_found) printf "%s,%s\n",FILENAME,$0}' {} \; > "subipo_$(date +"%Y%m%d").csv"
