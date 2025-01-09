#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
 * Loads the default configuration and applies any overrides
 * from environment variables if available.
 */
void load_config(Config *config) {
    // Load default settings
    config->timeout = DEFAULT_TIMEOUT;
    snprintf(config->download_dir, sizeof(config->download_dir), "%s", DEFAULT_DOWNLOAD_DIR);

    // Check for environment variable overrides
    char *env_timeout = getenv("IXXLER_TIMEOUT");
    if (env_timeout) {
        config->timeout = atoi(env_timeout);
    }

    char *env_download_dir = getenv("IXXLER_DIR");
    if (env_download_dir) {
        snprintf(config->download_dir, sizeof(config->download_dir), "%s", env_download_dir);
    }

    // Print configuration for debugging
    printf("[CONFIG] Loaded configuration:\n");
    printf("[CONFIG] Timeout: %d seconds\n", config->timeout);
    printf("[CONFIG] Download Directory: %s\n", config->download_dir);
}
