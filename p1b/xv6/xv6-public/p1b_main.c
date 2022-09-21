#include "types.h"
#include "stat.h"
#include "user.h"
#include "fcntl.h"

int main(void)
{
    printf(1, "Running trace: %d\n", trace("text.txt"));
    printf(1, "Runn`ing getcount: %d\n", getcount());
    open("text.txt", O_CREATE);
    printf(1, "Runn`ing getcount: %d\n", getcount());
    open("text.txt", O_CREATE);
    printf(1, "Runn`ing getcount: %d\n", getcount());
    open("text2.txt", O_CREATE);
    printf(1, "Runn`ing getcount: %d\n", getcount());
    printf(1, "Running trace: %d\n", trace("test.txt"));
    printf(1, "Runn`ing getcount: %d\n", getcount());
    open("test.txt", O_CREATE);
    printf(1, "Runn`ing getcount: %d\n", getcount());



    exit();
}