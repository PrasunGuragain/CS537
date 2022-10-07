#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <sys/stat.h>

void redirection(char *commandList, char **path, int num_of_path);
void handel_fork(char **parameters, char **path, char *command, int num_of_path, int redirecting, char *file_name);
void if_then(char *command);
void error_message();

// reads user input
int read_command(char cmd[], char *par[], char **path, int num_of_path)
{
    char *array[512], *commandList;
    commandList = malloc(512 * sizeof(char));

    char *command;
    command = malloc(512 * sizeof(char));
    size_t bufsize = 0;
    int getLine_return = 0;
    getLine_return = getline(&command, &bufsize, stdin);

    // batch file done
    if (getLine_return == -1){
        return 2;
    }
    if (strcmp(command, "") == 0)
    {
        return 0;
    }

    // if_then
    if (command[0] == 'i' && command[1] == 'f')
    {
        if_then(command);
        return -1;
    }

    // Redirection
    char *ret;
    ret = strchr(command, '>');
    if (ret != NULL)
    {
        redirection(command, path, num_of_path);
        return -1;
    }

    // parse the line into words
    int i = 0;
    commandList = strtok(command, " \t\n/0");
    while (commandList != NULL)
    {
        array[i] = strdup(commandList);
        i++;
        commandList = strtok(NULL, " \t\n");
    }

    // first word is the command
    strcpy(cmd, array[0]);

    // others are parameters
    int j = 0;
    while (j < i)
    {
        par[j] = array[j];
        j++;
    }

    // need "/0" right after the end of parameters
    par[i] = NULL;

    free(commandList);
    return 0;
}

// clears screen then wish shell starts
void prompt()
{
    static int first_time = 1;

    // clear screen if at the beginning
    if (first_time)
    {
        const char *clear_screen_ansi = " \e[1;1H\e[2J";
        write(STDERR_FILENO, clear_screen_ansi, 12);
        first_time = 0;
    }

    printf("wish> ");
}

// if any error due to bad syntax from user
void error_message()
{
    char error_message[30] = "An error has occurred\n";
    write(STDERR_FILENO, error_message, strlen(error_message));
    exit(0);
}

void cd_command(char *par)
{
    if (chdir(par) != 0)
    {
        error_message();
    }
}

void path_command(char **path, char **parameters, int *num_of_path)
{
    int i = 0;
    int j = 1;
    while (1)
    {
        if (parameters[j] == NULL)
        {
            break;
        }
        else
        {
            path[i] = parameters[j];
            (*num_of_path)++;
        }
        i++;
        j++;
    }
}

void execute(char **parameters, char **path, char *command, int *num_of_path)
{
    char *cmd;
    int i = 0;
    int j = 0;
    while (i < *num_of_path)
    {
        if (access(path[j], X_OK) != -1)
        {
            strcpy(cmd, path[j]);
            strcat(cmd, "/");
            strcat(cmd, command);
            printf("cmd: %s\n", cmd);
            execv(cmd, parameters);
            printf("cmd1: %s\n", cmd);
            exit(0);
        }

        // I believe +32 because int is 32 bit and path is a list of pointers to the first element of a string
        j += 1;

        i += 1;
    }
    printf("cmd2: %s\n", cmd);
    error_message();
}

void redirection(char *line, char **path, int num_of_path)
{
    // Get everything to left of ">" (operation)
    char *params_str = strtok(line, ">");

    // Get everything to right of ">" (file name)
    char *file_name = strtok(NULL, ">");
    file_name = strtok(file_name, " \n");

    // Stores all the parameters. If ls -l, this will store -l
    char *all_params[512];

    // the command. If ls -l, this will store ls
    char *current = strtok(params_str, " ");
    char *command = current;
    all_params[0] = command;

    int i = 1;
    while (current)
    {
        current = strtok(NULL, " ");
        all_params[i] = current;
        i++;
    }

    // I was wrong about parameters. If user type ls -l, parameters should be:
    // [ls, -1, null(/0)] and command should be: "ls"
    handel_fork(all_params, path, command, num_of_path, 1, file_name);
}

void handel_fork(char **parameters, char **path, char *command, int num_of_path, int redirecting, char *file_name)
{
    int pid = fork();
    if (pid == 0)
    {
        if (redirecting == 1)
        {
            // open file
            int fd = open(file_name, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);

            // make stdout go to file
            dup2(fd, 1);

            // make stderr go to file
            dup2(fd, 2);

            close(fd);
        }
        execute(parameters, path, command, &num_of_path);
        exit(1);
    }
    int status;
    waitpid(pid, &status, 0);
}

void if_then(char *line)
{
    char *temp_line = malloc(sizeof(char) * 512);
    strcpy(temp_line, line);

    // strstr() will point to 't' in the first then, so "then" and after
    char *then_and_after = strstr(temp_line, "then");

    char *array[512];
    char *current = strtok(line, " ");

    int i = 0;
    while (current)
    {
        array[i] = current;
        current = strtok(NULL, " ");
        i++;
    }

    // NOTES:
    // execv("one", ["one", /0]);
    // cat batch_file | ./wish

    free(temp_line);
}

void batchMode(char *file){
    freopen(file, "r", stdin);
}

int main(int argc, char *argv[])
{
    char command[512], *parameters[512];

    char *path[512];
    path[0] = "/bin";

    int num_of_path = 1;

    int isBatchMode = 0;

    FILE *fp;
    char **args;
    if (argc == 2)
    {
        if (!(fp = fopen(argv[1], "r")))
        {
            error_message();
            exit(1);
        }
        isBatchMode = 1;
    }
    else if (argc < 1 || argc > 2)
    {
        error_message();
        exit(1);
    }
    if (isBatchMode == 1){
        batchMode(argv[1]);
    }
    while (1)
    {
        if (isBatchMode == 0)
        {
            prompt(); // display prompt on screen
        }
        int read_return = read_command(command, parameters, path, num_of_path); // read input from terminal

        // if done redirection or if_then command, don't handel_fork() again
        if (read_return == -1)
        {
            continue;
        }
        else if (read_return == 2)
        {
            exit(0);
        }

        if (strcmp(command, "exit") == 0)
        {
            if (parameters[1] != NULL){
                error_message();
            }
            exit(0);
        }
        else if (strcmp(command, "cd") == 0)
        {
            cd_command(parameters[1]);
            continue;
        }
        else if (strcmp(command, "path") == 0)
        {
            num_of_path = 0;
            path_command(path, parameters, &num_of_path);
            continue;
        }

        // if no redirection, cd, exit, or path
        char *file_name = "";
        handel_fork(parameters, path, command, num_of_path, 0, file_name);
    }
    return 0;
}

//wait(NULL); // if problems, look at wait_pid(), and wif_signal()
    /*
    int pid = fork();
    if (pid != 0)
    {
        wait(NULL); // if problems, look at wait_pid(), and wif_signal()
    }
    else
    {
        if (redirecting == 1)
        {
            // open file
            int fd = open(file_name, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);

            // make stdout go to file
            dup2(fd, 1);

            // make stderr go to file
            dup2(fd, 2);

            close(fd);
        }
        execute(parameters, path, command, &num_of_path);
    }
    */