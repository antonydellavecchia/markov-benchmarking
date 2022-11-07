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

    for line in eachline(out)
        println(line)
    end

    wait(task)
    if !success(proc)
        error = eof(err) ? "unknown error" : readchomp(err)
        throw("Failed to run markov: $error")
    else
        open("$(path).mar") do matrix_file
            for line in eachline(matrix_file)
                println(line)
            end
        end
    end
end

function run_markov_polymake(path)
    in = Pipe()
    out = Pipe()
    err = Pipe()
    Base.link_pipe!(in, writer_supports_async=true)
    Base.link_pipe!(out, reader_supports_async=true)
    Base.link_pipe!(err, reader_supports_async=true)
    cmd = `$(polymake_cmd) --script $(pwd())/test_markov.pl path`
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
end

function benchmark(path)
    run_markov_4ti2(path)
    run_markov_polymake(path)
end
