
# protoc

[![protoc status
badge](https://sounkou-bioinfo.r-universe.dev/protoc/badges/version)](https://sounkou-bioinfo.r-universe.dev/protoc)

This package provides functions to download `protoc` and `protoc-go-gen`
binaries and generate Go code from `.proto` files. This should be useful
for R developers working with Protocol Buffers and Go.

For more information about Go support for Protocol Buffers, see the
[golang/protobuf GitHub repository](https://github.com/golang/protobuf).

# Download and Usage

``` r
library(protoc)

# Download protoc version 33.0
protoc_path <- download_protoc("33.0")

# Check that the file exists
stopifnot(file.exists(protoc_path))

# Check the version
actual_version <- get_protoc_version(protoc_path)
stopifnot(actual_version == "33.0")

# Check version using check_version (will error if mismatch)
check_version(protoc_path, "33.0")
#> [1] TRUE

# Use a temp directory for all test artifacts
tmp_dir <- tempdir()

# Install protoc-gen-go to a custom path and add to PATH
custom_pggo_dir <- file.path(tmp_dir, "pggo_bin")
dir.create(custom_pggo_dir, showWarnings = FALSE)
pggo_exe <- install_protoc_gen_go(version = "latest", out_path = file.path(custom_pggo_dir, "protoc-gen-go"))
#> go: google.golang.org/protobuf@v1.36.10 requires go >= 1.23; switching to go1.24.9
stopifnot(file.exists(pggo_exe))
Sys.setenv(PATH = paste(custom_pggo_dir, Sys.getenv("PATH"), sep = .Platform$path.sep))

# Generate Go code from a .proto file
proto_content <- '
syntax = "proto3";
package test;
option go_package = "github.com/example/testpb";

message Hello {
  string greeting = 1;
}
'
tmp_dir2 <- tempdir()
proto_file <- file.path(tmp_dir2, "test.proto")
writeLines(proto_content, proto_file)
go_out_dir <- file.path(tmp_dir2, "go_out")
protoc_path <- download_protoc("33.0")
go_file <- generate_go_from_proto(proto_file, go_out_dir, protoc_path = protoc_path)
#> 
#> Warning in generate_go_from_proto(proto_file, go_out_dir, protoc_path =
#> protoc_path): Go file was not generated at
#> /tmp/Rtmp8IZ4I6/go_out/test/test.pb.go
go_file <- file.path(go_out_dir, "github.com", "example", "testpb", "test.pb.go")
stopifnot(file.exists(go_file))
```
