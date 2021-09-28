using PackageCompiler

target_dir = get(ENV, "OUTDIR", "$(@__DIR__)/../PLextCompiled")
target_dir = replace(target_dir, "\\"=>"/")       # Change Windows paths to use "/"

package_dir = "."

println("Creating library in $target_dir")
PackageCompiler.create_library(package_dir, target_dir;
                                lib_name="plext",
                                precompile_execution_file=["$(@__DIR__)/generate_precompile.jl"],
                                precompile_statements_file=["$(@__DIR__)/additional_precompile.jl"],
                                incremental=false,
                                filter_stdlibs=true,
                                header_files = ["$(@__DIR__)/plext.h"],
                                force=true
                            )
