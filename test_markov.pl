use application "fulton";
use Time::HiRes qw(time);

sub run_markov {
  # read matrix file in 4ti2 matrix format
  my $matrix_file = $ARGV[0];
  my $file_type = $ARGV[1];
  
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

  my $input_matrix = new Matrix<Integer>(@rows);

  
  if ($file_type eq "polytope") {
    my $p = new Polytope(VERTICES=>transpose($input_matrix));

    my $initial_time = time();
    my $result = markov_basis($p);
    print time() - $initial_time;

    save($result, "${matrix_file}_polymake.json");

  } else {
    my $initial_time = time();
    my $result = markov_basis($input_matrix, {"use_kernel" => true});
    print time() - $initial_time;
    save($result, "${matrix_file}_polymake.json");
  }
}

run_markov();
