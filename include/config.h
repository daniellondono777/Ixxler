#ifndef CONFIG_H
#define CONFIG_H

#define DEFAULT_TIMEOUT 30
#define DEFAULT_DOWNLOAD_DIR "./downloads"

// Config structure to store runtime configuration
typedef struct {
    int timeout;
    char download_dir[256];
} Config;

// Function prototypes
void load_config(Config *config);

#endif // CONFIG_H
