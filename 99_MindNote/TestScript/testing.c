#include <stdio.h>

char* say_hello()
{
   return "hello world";
}

float calc_xyzzy()
{
     return 6.234;
}

int main(int argc, char** argv)
{
   if (argc>1) {
      if (argv[1][0] =='1') {
        fprintf(stdout,"%s\n",say_hello());
      } else if ( argv[1][0] == '2') {
        fprintf(stdout,"%g\n",calc_xyzzy());
      }
    }
    return 0;
}
