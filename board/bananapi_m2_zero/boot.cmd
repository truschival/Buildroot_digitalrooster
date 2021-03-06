setenv bootenv uEnv.txt

fatload mmc 0 ${scriptaddr} ${bootenv}
env import -t ${scriptaddr} ${filesize}

setenv root_fs ${ACTIVE_ROOT}

echo -------
echo trying to boot from ${root_fs}
echo -------


setenv fdt_high ffffffff
setenv bootargs console=ttyS0,115200 earlyprintk root=$root_fs rootwait

fatload mmc 0 $kernel_addr_r zImage
fatload mmc 0 $fdt_addr_r digitalrooster-bananapi-m2-zero.dtb
bootz $kernel_addr_r - $fdt_addr_r
