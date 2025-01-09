#include <curl/curl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "downloader.h"

// Callback function to write data into memory
size_t write_to_memory(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t total_size = size * nmemb;
    MemoryBuffer *mem = (MemoryBuffer *)userp;

    // Expand memory buffer
    unsigned char *ptr = realloc(mem->buffer, mem->size + total_size);
    if (ptr == NULL) {
        printf("[ERROR] Not enough memory for download\n");
        return 0; // Signal libcurl to stop
    }
    mem->buffer = ptr;

    // Copy data into buffer
    memcpy(&(mem->buffer[mem->size]), contents, total_size);
    mem->size += total_size;

    return total_size; // Signal libcurl to continue
}

// Download a file into memory
int download_file_to_memory(const char *url, MemoryBuffer *mem) {
    CURL *curl;
    CURLcode res;

    // Initialize the memory buffer
    mem->buffer = NULL;
    mem->size = 0;

    curl = curl_easy_init();
    if (!curl) {
        fprintf(stderr, "[ERROR] Failed to initialize libcurl\n");
        return 1;
    }

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_to_memory);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, mem);

    // Perform the download
    res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
        fprintf(stderr, "[ERROR] libcurl: %s\n", curl_easy_strerror(res));
    }

    // Cleanup
    curl_easy_cleanup(curl);

    // Return success or failure
    return (res == CURLE_OK) ? 0 : 1;
}
