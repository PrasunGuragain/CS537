#include "types.h"
#include "stat.h"
#include "user.h"

int main(void)
{
    printf(1, "Running trace: %d\n", trace("a_pathname"));
    printf(1, "Running getcount: %d\n", getcount());
    exit();
}