if [[ -z $1 ]]
then echo "directory name not provided"
else 
deno -A ../scripts/makeDir.js $1
code .
fi

