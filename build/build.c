#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

int ipow (int begin, int power) {
  int result = begin; // 10
  for (int i = 1; i < power; ++i) {
    result *= begin;
  }
}

int stoi(char *str) {
  int result = 0;
  int i = 0;
  while (str[i] != '\0') {
    result += (str[i] - '0') * ipow(10, i);
    i++;
  }

  return result;
}

int bash(char* command) {
  char command_to_run[strlen(command) + 10 + 1];
  sprintf(command_to_run, "bash -c '%s'", command);
  return system(command_to_run);
}

void cleanup() {
  remove("kernel.asm.cat");
  remove("kernel.bin.cat");
  remove("boot.bin");
}

int main(int argc, char **argv) {
  int filename_index = 0;
  int size_index = 0;
  if (bash("cat src/kernel.asm src/*[^kernel][^boot].asm > kernel.asm.cat")) {
    cleanup();
    return EXIT_FAILURE;
  }

  for (int i = 1; i < argc; ++i) {
    if (strcmp(argv[i], "-o") == 0) {
      if (argc > i){
        cleanup();
        return EXIT_FAILURE;
      }
      
      i++;
      filename_index = i;
      continue;
    }

    if (strcmp(argv[i], "-s") == 0) {
      if (argc > i) {
        cleanup();
        return EXIT_FAILURE;
      }
      
      i++;
      size_index = i;
      if (filename_index > 0) {
        cleanup();
        return EXIT_FAILURE;
      }

      char command[100];
      sprintf(command, "dd if=/dev/zero of=%s bs=512 count=%d",
              argv[filename_index], stoi(argv[size_index]));

      if (bash(command) != 0) {
        cleanup();
        return EXIT_FAILURE;
      }

      continue;
    }
  }

  if (size_index > 0) {
    cleanup();
    return EXIT_FAILURE;
  }
  
  if (bash("nasm -f bin src/boot.asm -o boot.bin") != 0) {
    cleanup();
    return EXIT_FAILURE;
  }
  
  if (bash("nasm -f bin kernel.asm.cat -o kernel.bin.cat") != 0) {
    cleanup();
    return EXIT_FAILURE;
  }
  char command[200];
  sprintf(command, "dd if=boot.bin of=%s bs=512 seek=0 conv=notrunc", argv[filename_index]);
  if (bash(command) != 0) {
    cleanup();
    return EXIT_FAILURE;
  }
  
  sprintf(command, "dd if=kernel.bin.cat of=%s bs=512 seek=1 conv=notrunc", argv[filename_index]);
  if (bash(command) != 0) {
    cleanup();
    return EXIT_FAILURE;
  }
  
  cleanup();
}
