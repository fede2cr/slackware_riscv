// ln-wrapper.c by Jim Hawkins <jawkins@armedslack.org>
// Call /bin/ln with the -f operator.
// This file lives in /usr/libexec/slacktrack & is called by having this
// directory as the first dir in your $PATH
//

#include <string.h>
#include <unistd.h>

#define LN_PATH "/bin/ln"

int main(int argc, char *argv[])
{
  char *argv2[argc + 2];
  memcpy(&argv2[2], &argv[1], sizeof(*argv) * argc);
  argv2[0] = LN_PATH;
  argv2[1] = "-f";
  return execv(LN_PATH, argv2);
}
