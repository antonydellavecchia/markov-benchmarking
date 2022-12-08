using Oscar: replace_TeX
using Base: reduced_indices
using Oscar
using TimerOutputs

const to = TimerOutput()

include("LocalVariables.jl")

function read_4ti2_matrix_file(path)
    result = []
    open("$path") do file
        matrix_string = "["
        for (i, line) in enumerate(eachline(file))
            if i == 1
                continue
            end

            if i == 2
                matrix_string *= "$line"
            else
                matrix_string *= "; $line"
            end
        end

        matrix_string *= "]"

        result = fmpz_mat(eval(Meta.parse(matrix_string)))
    end

    return result
end

"""
Find all lattices bases subsets of a markov basis from a file in 4ti2 format
"""
function get_bases_from(path)
    markov_matrix = read_4ti2_matrix_file(path)
    markov_matroid = matroid_from_matrix_rows(markov_matrix)

    return bases(markov_matroid)
end


function run_markov_4ti2(path)
    in = Pipe()
    out = Pipe()
    err = Pipe()
    Base.link_pipe!(in, writer_supports_async=true)
    Base.link_pipe!(out, reader_supports_async=true)
    Base.link_pipe!(err, reader_supports_async=true)
    println(path)
    cmd = Oscar.lib4ti2_jll.markov
    proc = run(pipeline(`$(cmd) --generation project-and-lift --minimal=no --precision=arb $(path)`, stdin=in, stdout=out, stderr=err), wait=false)

    task = @async begin
        write(in, "")
        close(in)
    end

    close(in.out)
    close(out.in)
    close(err.in)

    wait(task)
    if !success(proc)
        error = eof(err) ? "unknown error" : readchomp(err)
        throw("Failed to run markov: $error")
    end

    return binomial_exponents_to_ideal(read_4ti2_matrix_file("$(path).mar"))
end

function run_markov_polymake(path)
    in = Pipe()
    out = Pipe()
    err = Pipe()
    Base.link_pipe!(in, writer_supports_async=true)
    Base.link_pipe!(out, reader_supports_async=true)
    Base.link_pipe!(err, reader_supports_async=true)
    cmd = nothing

    if contains(path, ".mat")
        cmd = `$(polymake_cmd) --script $(pwd())/test_markov.pl $path polytope`
    else
        cmd = `$(polymake_cmd) --script $(pwd())/test_markov.pl $path`
    end
    
    proc = run(pipeline(cmd, stdin=in, stdout=out, stderr=err), wait=false)

    task = @async begin
        write(in, "")
        close(in)
    end

    close(in.out)
    close(out.in)
    close(err.in)

    for line in eachline(out)
        println(line)
    end

    wait(task)
    if !success(proc)
        error = eof(err) ? "unknown error" : readchomp(err)
        throw("Failed to run markov: $error")
    end

    result = fmpz_mat(Matrix{Int64}(load("$(path)_polymake.json")))

    return binomial_exponents_to_ideal(result)
end

function benchmark(path)
    ideal_4ti2 = run_markov_4ti2(path)
    lattice_ideal = nothing
    
    if contains(path, ".mat")
        mat = read_4ti2_matrix_file(path)
        lattice = transpose(kernel(mat)[2])
        lattice_ideal = binomial_exponents_to_ideal(lattice)
    else
        @timeit to "4ti2" lattice = read_4ti2_matrix_file(path)
        lattice_ideal = binomial_exponents_to_ideal(lattice)
    end
    
    if is_groebner(ideal_4ti2, lattice_ideal)
        println("4ti2 correct")
    else
        println("4ti2 incorrect")
    end

    ideal_polymake = run_markov_polymake(path)
    
    if is_groebner(ideal_polymake, lattice_ideal)
        println("polymake correct")
    else
        println("polymake incorrect")
    end
end

function is_groebner(I::MPolyIdeal, lattice_ideal::MPolyIdeal)
    R = base_ring(I)
    
    for g in gens(lattice_ideal)
        if 0 != normal_form(g, I;)
            return false
        end
    end

    for (f, g) in Hecke.subsets(gens(I), 2)
        x_gamma = lcm(leading_monomial(f), leading_monomial(g))
        s_poly = divexact(x_gamma * f, leading_term(f)) -
            divexact(x_gamma * g, leading_term(g))

        if 0 != normal_form(s_poly, I)
            return false
        end
    end
    
    return true
end

function benchmark_folder(folder_path)
    foreach(readdir(folder_path)) do f
        if endswith(f, ".mat")
            @timeit to "$f" begin
                benchmark("$folder_path/$f")
            end
        end
    end
end
