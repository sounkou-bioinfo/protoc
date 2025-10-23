# Load the package
library(protoc)

# Download protoc version 33.0
protoc_path <- download_protoc("33.0")

# Check that the file exists
if (!file.exists(protoc_path)) stop("protoc binary was not downloaded.")

# Check the version
actual_version <- get_protoc_version(protoc_path)
if (actual_version != "33.0") stop(sprintf("Expected version 33.0 but got %s", actual_version))

# Check version using check_version (will error if mismatch)
check_version(protoc_path, "33.0")

cat("protoc 33.0 downloaded and verified successfully\n")
