# this is heavily based on https://github.com/LTLA/biocmake/blob/02027f30f3ace195edbf5a8b6e5823dd048a6384/R/download.R

defaultDownloadVersion <- function() {
    "33.0"
}

#' Download precompiled protoc binaries
#'' This function downloads precompiled `protoc` binaries for a specified version.
#' @param version A character string specifying the version of `protoc` to download. Default is "33.0".
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
    download.file(
        url = paste0(base_url, file_name),
        destfile = file.path(destdir, file_name)
    )
    unzip(
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
    ver_output <- system2(normalizePath(protoc_path), args = "--version", stdout = TRUE)
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
