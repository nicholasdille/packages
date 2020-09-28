for file in variables github; do
    >&2 echo "Sourcing ${file}..."
    source <(curl --silent --location --fail https://pkg.dille.io/.scripts/${file}.sh)
done