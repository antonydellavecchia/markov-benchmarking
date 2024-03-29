use File::Path qw(make_path);
use application "polytope";
  
sub write_fano_4ti2_files {
  my $fano_folder = $ARGV[0];
  my $polyDB = polyDB();
  my $collection = $polyDB->get_collection("Polytopes.Lattice.SmoothReflexive");

  for (my $i = 4; $i < 7; $i++) {
    my $fano_polytopes = $collection->find({"DIM"=>$i}, {"limit"=>2});
    make_path($fano_folder."dimension_".$i);

    while ($fano_polytopes->has_next()) {
      my $polytope = $fano_polytopes->next();
      my $polytope_name = $polytope->name;
      my $file_name = $fano_folder."dimension_".$i."/".$polytope_name."lattice_points";

      open(my $fh, ">$file_name.mat");

      my $num_ver = $polytope->N_VERTICES;
      my $ver_dim = $i + 1;
      print $fh "$ver_dim $num_ver \n";
      print $fh transpose($polytope->LATTICE_POINTS);
      close($fh);
    }
  }
}

write_fano_4ti2_files();
