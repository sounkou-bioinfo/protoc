# Load the package
library(protoc)

# Download protoc version 33.0
protoc_path <- download_protoc("33.0")

# Check that the file exists
if (!file.exists(protoc_path)) stop("protoc binary was not downloaded.")

# Check the version
actual_version <- get_protoc_version(protoc_path)
if (actual_version != "33.0") {
    stop(sprintf("Expected version 33.0 but got %s", actual_version))
}

# Check version using check_version (will error if mismatch)
check_version(protoc_path, "33.0")

cat("protoc 33.0 downloaded and verified successfully\n")

# Use a temp directory for all test artifacts
tmp_dir <- tempdir()

# Install protoc-gen-go to a custom path and add to PATH
custom_pggo_dir <- file.path(tmp_dir, "pggo_bin")
dir.create(custom_pggo_dir, showWarnings = FALSE)
pggo_exe <- install_protoc_gen_go(version = "latest", out_path = file.path(custom_pggo_dir, "protoc-gen-go"))
if (!file.exists(pggo_exe)) {
    stop("protoc-gen-go was not installed at ", pggo_exe)
}
cat("protoc-gen-go installed at ", pggo_exe, "\n")
Sys.setenv(PATH = paste(custom_pggo_dir, Sys.getenv("PATH"), sep = .Platform$path.sep))

# Test generate_go_from_proto
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
go_file <- file.path(go_out_dir, "github.com", "example", "testpb", "test.pb.go")
if (!file.exists(go_file)) {
    stop("Go file was not generated at ", go_file)
}
cat("Go file generated at ", go_file, "\n")
