use application "fulton";


sub run_markov {
  # read matrix file in 4ti2 matrix format
  my $matrix_file = $ARGV[0];
  open(INPUT, "< ${matrix_file}");
  my $first_line = true;
  my @rows = ();
  
  while(<INPUT>) {
    if ($first_line) {
      $first_line = false;
    } else {
      push(@rows, $_);
    }
  }
  close(INPUT);
  
  my $lattice = new Matrix<Integer>(@rows);
  my $initial_time = time();

  print markov_basis($lattice);

  print  "polymake took : ", time() - $initial_time, " \n";
}

run_markov();

