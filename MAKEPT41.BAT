erase pibt.exe
erase pibt.map
tpc /m /$d+ /$l- /$r- /$s- /$t+ /$v- /$f- /$B- /$N- /$I- pibterm.pas
tpmap pibterm
erase pibterm.tpm
rename pibterm.exe pibt.exe
rename pibterm.map pibt.map
overlay /d pibt.exe pibterm.exe >pibtovr.lis
erase pibt.map
erase pibt.exe
exepack pibterm.exe pibt2.exe
erase pibterm.exe
rename pibt2.exe pibterm.exe
