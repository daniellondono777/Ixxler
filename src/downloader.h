#ifndef DOWNLOADER_H
#define DOWNLOADER_H

#include <stddef.h>

// Memory buffer to store downloaded data
typedef struct {
    unsigned char *buffer;
    size_t size;
} MemoryBuffer;

// Function to download a file into memory
int download_file_to_memory(const char *url, MemoryBuffer *mem);

#endif // DOWNLOADER_H
