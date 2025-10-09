# get argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <record_count>"
    exit 1
fi

record_count=$1

# make sure folder doesnt already exist
if [ -d "$record_count" ]; then
    echo "Folder $record_count already exists"
    exit 1
fi

# parse to actual number (k, M, G)
# 10M -> 10000000
record_count_number=$(echo $record_count | sed -e 's/M/*1000000/g' | sed -e 's/K/*1000/g' | sed -e 's/G/*1000000000/g' | bc)

# aging count should be 30% of record count
aging_count=$(echo "$record_count_number * 0.3" | bc | cut -d'.' -f1)

# copy the template folder to "workloads/record_count"
cp -r template $record_count

# replace the placeholders with actual values
find $record_count -type f -exec sed -i -e "s/@@recordcount@@/$record_count_number/g" {} \;
find $record_count -type f -exec sed -i -e "s/@@agingcount@@/$aging_count/g" {} \;


