#include <stdio.h>
#include <string.h>

void func1();

int main(int args, char **argc) {
  // char buf[10] = {1,2,0,0,3,1,1,1,1,1};
  // unsigned int len = 0;
  // memcpy(&len, buf, 4);
  // printf("Len: %d\n",len);
  func1();
}

unsigned int n = 3;
unsigned int x = 2;
unsigned int y = 2;
void func1() { 
  const int n2 = n * n; 
  unsigned int result = 0;
  if (2 * (x * n - y) - n2 >= 0) result = 1;
  printf("%d\n",result);
}
