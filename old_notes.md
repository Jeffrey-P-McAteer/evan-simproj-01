
  If gather_den_flux.cc errors about code like "int x = 5; int x = 5;" just remove the variable dec;
  hopefully that's not mathematically significant?

  also we replace MPI_Errhandler_get with MPI_Comm_get_errhandler in main.cc because
  modern MPI does not have MPI_Errhandler_get defined.

  for last build command, remove "-l<doesnt exist>" with
  "-ldrfftw_mpi -ldfftw_mpi -ldrfftw -ldfftw -lm -lhdf5_hl -lhdf5"
  and ./eppic.x should get built!

  Once ./eppic.x is built, copy an input file from input_files and name it eppic.i

  ####> ./eppic.x eppic.i
  ####> gdb -batch -ex "run" -ex "bt" -ex "info locals" --args ./eppic.x eppic.i
