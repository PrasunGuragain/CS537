#include "types.h"
#include "stat.h"
#include "user.h"

int main(void)
{
    //printf(1, "settickets: %d\n", settickets());
    //printf(1, "getpinfo:  %d\n", getpinfo());
    int a = 1;
    int b = 2;
    printf(1, "mprotect:  %d\n", mprotect(&a, 1));
    printf(1, "munprotect:  %d\n", munprotect(&b, 1));
    exit();
}