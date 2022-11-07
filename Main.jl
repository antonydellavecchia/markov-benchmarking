using Oscar
include("LocalVariables.jl")

function run_markov_4ti2(path)
    in = Pipe()
    out = Pipe()
    err = Pipe()
    Base.link_pipe!(in, writer_supports_async=true)
    Base.link_pipe!(out, reader_supports_async=true)
    Base.link_pipe!(err, reader_supports_async=true)

    cmd = Oscar.lib4ti2_jll.markov
    proc = run(pipeline(`$(cmd) $(path) --generation project-and-lift --minimal 'no'`, stdin=in, stdout=out, stderr=err), wait=false)

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

    result = []
    open("$(path).mar") do file
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
    return binomial_exponents_to_ideal(result)
end

function run_markov_polymake(path)
    in = Pipe()
    out = Pipe()
    err = Pipe()
    Base.link_pipe!(in, writer_supports_async=true)
    Base.link_pipe!(out, reader_supports_async=true)
    Base.link_pipe!(err, reader_supports_async=true)
    cmd = `$(polymake_cmd) --script $(pwd())/test_markov.pl $path`
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
    o = lex(base_ring(ideal_4ti2))
    
    if issubset(groebner_basis(ideal_4ti2, ordering=o), gens(ideal_4ti2))
        println("4ti2 correct")
    else
        println("4ti2 incorrect")
    end

    ideal_polymake = run_markov_polymake(path)
    o = lex(base_ring(ideal_polymake))
    if issubset(groebner_basis(ideal_polymake), gens(ideal_polymake))
        println("polymake correct")
    else
        println("polymake incorrect")
    end
end
