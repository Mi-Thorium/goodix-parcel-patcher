#!/bin/bash

rm -rf tmp output
mkdir tmp output

for f in `bash -c 'cd input/ && ls *.so'`; do
    # 1. Ghidra work
    [ -f "input/${f}.c" ] || continue
    grep -B10 "Parcel aPStack" input/${f}.c | grep "//" > tmp/${f}_f || continue
    sed -i '/WARNING:/d' tmp/${f}_f

    # 2. `objdump`
    aarch64-linux-android-objdump -d input/${f} > tmp/${f}.asm || continue

    # 3. Execute the script (arg1: step 2, arg2: step 1, arg3: output)
    cp input/${f} output/${f}
    python3 script.py tmp/${f}.asm tmp/${f}_f output/${f} > tmp/${f}.log || continue

    # sha1sum
    input_sha1sum="$(sha1sum input/${f}|cut -c -40)"
    output_sha1sum="$(sha1sum output/${f}|cut -c -40)"
    if [ "$input_sha1sum" == "$output_sha1sum" ]; then
        echo "No change for output/${f}, Delete it"
        rm output/${f}
    fi
    echo "${f}|${input_sha1sum}|${output_sha1sum}"
done
