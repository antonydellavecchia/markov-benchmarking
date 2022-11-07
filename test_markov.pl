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

  my $result = markov_basis($lattice);
  save($result, "${matrix_file}_polymake.json");
}

run_markov();

