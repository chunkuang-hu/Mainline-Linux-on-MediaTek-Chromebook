  image=$1/arch/arm64/boot/Image
  lz4 -20 -z -f -m ${image}
  chromebook_dtbs=$(find $1/arch/arm64/boot -name "*kappa*.dtb" | LC_COLLATE=C sort)

  echo ${chromebook_dtbs}
  echo ${chromebook_dtbs} | ./generate_chromebook_its.sh ${image}.lz4 arm64 lz4 > kernel.its
