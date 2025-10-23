# this is heavily based on https://github.com/LTLA/biocmake/blob/02027f30f3ace195edbf5a8b6e5823dd048a6384/R/download.R

defaultDownloadVersion <- function() {
    "33.0"
}

#' Download precompiled protoc binaries
#'
#' This function downloads precompiled `protoc` binaries for a specified version.
#' @param version A character string specifying the version of `protoc` to download. Default is "33.0".
#' @param dest_file_path The destination file path for the downloaded protoc binary. Default is the extracted binary name.
#' @return The path to the downloaded `protoc` binary.
#' @examples
#' \dontrun{
#' protoc_path <- download_protoc("33.0")
#' }
#' @export
download_protoc <- function(
  version = defaultDownloadVersion(),
  dest_file_path = basename(bin_file_name_extract())
) {
    base_url <- sprintf(
        "https://github.com/protocolbuffers/protobuf/releases/download/v%s/",
        version
    )
    sinfo <- Sys.info()
    ssys <- sinfo[["sysname"]]
    destdir <- tempdir()
    if (ssys == "Linux") {
        file_name <- sprintf(get_linux_format(), version)
    } else if (ssys == "Darwin") {
        file_name <- sprintf(get_mac_format(), version)
    } else {
        file_name <- sprintf(get_windows_format(), version)
    }
    utils::download.file(
        url = paste0(base_url, file_name),
        destfile = file.path(destdir, file_name)
    )
    utils::unzip(
        zipfile = file.path(destdir, file_name),
        files = bin_file_name_extract(),
        exdir = destdir
    )
    file.copy(
        from = file.path(destdir, bin_file_name_extract()),
        to = dest_file_path
    )
    Sys.chmod(dest_file_path, mode = "0777")
    return(normalizePath(dest_file_path, mustWork = TRUE))
}


bin_file_name_extract <- function() {
    sinfo <- Sys.info()
    ssys <- sinfo[["sysname"]]
    if (ssys == "Windows") {
        file.path("bin", "protoc.exe")
    } else {
        file.path("bin", "protoc")
    }
}

get_linux_format <- function() {
    sinfo <- Sys.info()
    smach <- sinfo[["machine"]]
    if (smach == "aarch64") {
        "protoc-%s-linux-aarch64.zip"
    } else {
        "protoc-%s-linux-x86_64.zip"
    }
}

get_mac_format <- function() {
    "protoc-%s-osx-universal_binary.zip"
}

get_windows_format <- function() {
    "protoc-%s-win64.zip"
}


#' Get protoc version
#'' This function retrieves the version of the installed `protoc` binary.
#' @param protoc_path The path to the `protoc` binary.
#' @return A character string representing the version of `protoc`
#' @export
get_protoc_version <- function(protoc_path) {
    ver_output <- system2(
        normalizePath(protoc_path),
        args = "--version",
        stdout = TRUE
    )
    sub("^libprotoc ", "", ver_output)
}

#' Check protoc version
#'' This function checks if the installed `protoc` binary matches the expected version.
#' @param protoc_path The path to the `protoc` binary.
#' @param expected_version The expected version string.
#' @return TRUE if the versions match, otherwise throws an error.
#' @export
check_version <- function(protoc_path, expected_version) {
    actual_version <- get_protoc_version(protoc_path)
    if (actual_version != expected_version) {
        stop(
            sprintf(
                "Version mismatch: expected %s but got %s",
                expected_version,
                actual_version
            ),
            call. = FALSE
        )
    }
    TRUE
}

#' Find the Go executable
#' @return The path to the Go executable, or throws an error if not found.
#' @export
find_go <- function() {
    go_path <- Sys.which("go")
    if (go_path == "") {
        stop("Go executable not found in PATH. Please install Go and ensure it is available in your PATH.")
    }
    go_path
}

#' Install protoc-gen-go plugin
#' @param version The version of protoc-gen-go to install (default: latest)
#' @param out_path The full path where to install the protoc-gen-go executable (optional, default: $GOPATH/bin or Go's default bin dir)
#' @return The path to the installed protoc-gen-go executable
#' @export
install_protoc_gen_go <- function(version = "latest", out_path = NULL) {
    go <- find_go()
    pkg <- if (version == "latest") {
        "google.golang.org/protobuf/cmd/protoc-gen-go@latest"
    } else {
        sprintf("google.golang.org/protobuf/cmd/protoc-gen-go@%s", version)
    }
    # Determine bin path
    go_env <- system2(go, c("env", "GOBIN"), stdout = TRUE)
    gobin <- if (go_env != "") go_env else Sys.getenv("GOBIN")
    if (gobin == "") {
        go_env <- system2(go, c("env", "GOPATH"), stdout = TRUE)
        gobin <- file.path(go_env, "bin")
    }
    if (!is.null(out_path)) {
        gobin <- dirname(out_path)
        dir.create(gobin, showWarnings = FALSE, recursive = TRUE)
        old_gobin <- Sys.getenv("GOBIN")
        Sys.setenv(GOBIN = gobin)
        on.exit(Sys.setenv(GOBIN = old_gobin), add = TRUE)
    }
    res <- system2(go, c("install", pkg), stdout = TRUE, stderr = TRUE)
    message(paste(res, collapse = "\n"))
    exe <- file.path(gobin, if (.Platform$OS.type == "windows") "protoc-gen-go.exe" else "protoc-gen-go")
    if (!file.exists(exe)) {
        stop("protoc-gen-go was not installed at ", exe)
    }
    return(normalizePath(exe))
}

#' Generate Go code from a proto file
#'
#' @param proto_file Path to the .proto file.
#' @param go_out_dir Output directory for Go code.
#' @param protoc_path Path to the protoc binary (optional, will use download_protoc() if not provided).
#' @param proto_path Directory to use as --proto_path (optional, defaults to dirname(proto_file)).
#' @param protoc_gen_go_version Version of protoc-gen-go to use (default: same as protoc version).
#' @return Path to the generated Go file(s).
#' @export
generate_go_from_proto <- function(proto_file, go_out_dir, protoc_path = NULL, proto_path = NULL, protoc_gen_go_version = NULL) {
    if (is.null(protoc_path)) {
        protoc_path <- download_protoc()
    }
    find_go() # will error if not found
    if (is.null(protoc_gen_go_version)) {
        protoc_gen_go_version <- get_protoc_version(protoc_path)
    }
    # Install protoc-gen-go if not found or wrong version
    pggo_path <- Sys.which("protoc-gen-go")
    if (pggo_path == "") {
        install_protoc_gen_go(protoc_gen_go_version)
        pggo_path <- Sys.which("protoc-gen-go")
        if (pggo_path == "") stop("protoc-gen-go could not be installed or found in PATH.")
    }
    if (is.null(proto_path)) {
        proto_path <- dirname(proto_file)
    }
    dir.create(go_out_dir, showWarnings = FALSE, recursive = TRUE)
    old_wd <- getwd()
    setwd(proto_path)
    on.exit(setwd(old_wd), add = TRUE)
    res <- system2(
        protoc_path,
        args = c(
            sprintf("--proto_path=%s", proto_path),
            sprintf("--go_out=%s", go_out_dir),
            basename(proto_file)
        ),
        stdout = TRUE,
        stderr = TRUE
    )
    message(paste(res, collapse = "\n"))
    # Return the path(s) to generated Go file(s)
    go_pkg_dir <- file.path(go_out_dir, tools::file_path_sans_ext(basename(proto_file)))
    go_file <- file.path(go_pkg_dir, paste0(tools::file_path_sans_ext(basename(proto_file)), ".pb.go"))
    if (!file.exists(go_file)) {
        warning("Go file was not generated at ", go_file)
    }
    return(go_file)
}
