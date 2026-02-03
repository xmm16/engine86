#include <assert.h>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <unordered_map>

std::unordered_map<std::string, std::string> aliases;

void manage_alias_creation(std::istringstream file) {
  std::string word;
  while (file >> word) {
    if (word.substr(0, 6) == "@alias") {
      while (word.find(")") == std::string::npos) {
        std::string next;
        if (!(file >> next)) {
          std::cout << "File ended before parenthesis closed:\n"
                    << word << '\n';
          assert(0);
        }

        word += next;
      }

      // now we have the full string with the parenthesis
      bool start_recording = false;
      bool switch_words = false;
      std::string var_name = "";
      std::string var_value = "";

      for (char c : word) {
        if (c == '(') {
          start_recording = true;
          continue;
        } else if (c == ')') {
          start_recording = false;
          continue;
        } else if (c == ',') {
          switch_words = true;
          continue;
        }

        if (start_recording) {
          if (!switch_words) {
            var_name += c;
          } else {
            var_value += c;
          }
        }

        if (var_name == "alias") {
          std::cout << "You can't name an alias \"alias\" :/\n";
          assert(0);
        }
      }
      aliases[var_name] = var_value;
    }
  }
}

int main(int argc, char **argv) {
  std::ifstream file(argv[1]);
  std::ofstream outfile(argv[2]);
  std::string word;

no_log_line:
  while (std::getline(file, word)) {
    size_t index;
    while ((index = word.find('@')) != std::string::npos) {
      size_t original_index = index;
      index++;
      std::string fullword = "";
      while (std::isalnum(word[index]) || word[index] == '_') {
        fullword += word[index];
        index++;
      }

      if (fullword == "alias") {
        manage_alias_creation(std::istringstream(word));
        goto no_log_line;
      }

      if (aliases.count(fullword) == 0) {
        std::cout << "Word \"" << fullword << "\" not found!\n";
        return EXIT_FAILURE;
      }

      word.replace(original_index, fullword.length() + 1, aliases[fullword]);
    }
    outfile << word << '\n';
  }

  return EXIT_SUCCESS;
}
