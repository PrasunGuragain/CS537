#include "types.h"
#include "stat.h"
#include "user.h"

int main(void)
{
    printf(1, "settickets: %d\n", settickets());
    printf(1, "getpinfo:  %d\n", getpinfo());
    exit();
}