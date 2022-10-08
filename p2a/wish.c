#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <sys/stat.h>

int read_command(char cmd[], char *par[], char **path, int num_of_path, int isBatchMode, FILE *fp);
void handel_fork(char **parameters, char **path, char *command, int num_of_path, int redirecting, char *file_name);
void execute(char **parameters, char **path, char *command, int *num_of_path, int redirecting, char *file_name);
int redirection(char *commandList, char **path, int num_of_path);
void batchMode(char *file);
void cd_command(char *par);
void path_command(char **path, char **parameters, int *num_of_path);
void if_then(char *line);
void prompt();
void error_message();
void error_message_without_exit();

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
    int read_return = 0;

    // TODO: if one line not at end, ignores last line.
    // Also, redo's lines from recent path, or something similar
    while (1)
    {   
        if (isBatchMode == 0)
        {
            prompt(); // display prompt on screen
        }

        read_return = read_command(command, parameters, path, num_of_path, isBatchMode, fp); // read input from terminal

        
        if (read_return == 2) // batch file ended
        {
            break;
        }
        
        // if done redirection or if_then command, don't handel_fork() again
        if (read_return == -1)
        {
            continue;
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
        
        else{
            // if no redirection, cd, exit, or path
            char *file_name = "";
            handel_fork(parameters, path, command, num_of_path, 0, file_name);
        }
    }
    return 0;
}

// reads user input
int read_command(char cmd[], char *par[], char **path, int num_of_path, int isBatchMode, FILE *fp)
{
    char *array[512], *commandList;
    commandList = malloc(512 * sizeof(char));

    char *command;
    command = malloc(512 * sizeof(char));
    size_t bufsize = 0;
    int getLine_return = 0;

    if (isBatchMode == 1){
        getLine_return = getline(&command, &bufsize, fp);
    }
    else{
        getLine_return = getline(&command, &bufsize, stdin);
    }

    // batch file done
    if (getLine_return < 0){
        return 2;
    }

    if (strcmp(command, "") == 0)
    {
        return -1;
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
    commandList = strtok(command, " \t\n");
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

void handel_fork(char **parameters, char **path, char *command, int num_of_path, int redirecting, char *file_name)
{
    int pid = fork();
    if (pid > 0){
        int status;
        waitpid(pid, &status, 0);
    }
    else if (pid == 0){
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
        execute(parameters, path, command, &num_of_path, 0, file_name);
        exit(1);
    }
}

// when doing strcpy and strcat, use malloc first
void execute(char **parameters, char **path, char *command, int *num_of_path, int redirecting, char *file_name)
{
    char *cmd = malloc(10000);
    int i = 0;
    while (i < *num_of_path)
    {
        strcpy(cmd, path[i]);
        strcat(cmd, "/");
        strcat(cmd, command);
        if (access(cmd, X_OK) != 0){
            i++;
            continue;
        }
        execv(cmd, parameters);
        error_message();
    }
    error_message();
}

int redirection(char *line, char **path, int num_of_path)
{
    // Get everything to left of ">" (operation)
    char *params_str = strtok(line, ">");

    //printf("params_str: %s\n", params_str);

    char *cpy_file_name;
    cpy_file_name = malloc(10000);

    // Get everything to right of ">" (file name)
    char *file_name;
    file_name = malloc(10000);
    file_name = strtok(NULL, ">");
    file_name = strtok(file_name, "\n");

    //printf("file_name: %s\n", file_name);

    // if no file name given
    if (file_name == NULL){
        error_message();
    }

    strcpy(cpy_file_name, file_name);

    // if multiple file name given
    int num_of_files_given = 0;
    //printf("cpy_file_name: %s\n", cpy_file_name);
    char *current2 = strtok(cpy_file_name, " ");
    while (current2){
        //printf("current2: %s\n", current2);
        num_of_files_given++;
        current2 = strtok(NULL, " ");
    }
    //printf("num_of_files_given: %d\n", num_of_files_given);
    if (num_of_files_given != 1){
        error_message_without_exit();
        return -1;
    }

    // Stores all the parameters. If ls -l, this will store -l
    char *all_params[512];

    // the command. If ls -l, this will store ls
    char *current = strtok(params_str, " ");
    char *command = current;
    all_params[0] = command;

    //printf("all_params[0]: %s\n", all_params[0]);

    int i = 1;
    while (current)
    {
        current = strtok(NULL, " ");
        all_params[i] = current;
        //printf("all_params[%d]: %s\n", i, all_params[i]);
        i++;
    }

    // I was wrong about parameters. If user type ls -l, parameters should be:
    // [ls, -1, null(/0)] and command should be: "ls"
    handel_fork(all_params, path, command, num_of_path, 1, file_name);

    return 0;
}

void batchMode(char *file){
    freopen(file, "r", stdin);
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

void if_then(char *line)
{
    char *temp_line = malloc(sizeof(char) * 512);
    strcpy(temp_line, line);

    // strstr() will point to 't' in the first then, so "then" and after
    char *then_and_after = strstr(temp_line, "then");

    char *all_commands[512];
    char *current1 = strtok(line, " ");

    int if_index = -1;
    int comparator_index = -1;
    int then_index = -1;
    int fi_index = -1;

    
    int check_for_if = 0;
    int check_for_comparator = 0;
    int check_for_then = 0;
    int check_for_fi = 0;

    int i = 0;
    while (current1)
    {
        all_commands[i] = current1;

        // keep track of index of "if"
        if (strcmp(all_commands[i], "if") == 0 && check_for_if == 0){
            if_index = i;
            check_for_if = 1;
        }

        // keep track of index of "comparator"
        if ((strcmp(all_commands[i], "==") == 0 || strcmp(all_commands[i], "!=") == 0) && check_for_comparator == 0){
            comparator_index = i;
            check_for_comparator = 1;
        }
        
        // keep track of index of "then"
        if (strcmp(all_commands[i], "then") == 0 && check_for_then == 0){
            then_index = i;
            check_for_then = 1;
        }

         // keep track of index of "fi"
        if (strcmp(all_commands[i], "fi\n") == 0 && check_for_fi == 0){
            fi_index = i;
            check_for_fi = 1;
        }

        current1 = strtok(NULL, " ");
        i++;
    }
    all_commands[i-1][strcspn(all_commands[i-1], "\n")] = 0;
    int size = i - 1;

    // no "if", comparator, "then", or "fi"
    if (if_index == -1 || comparator_index == -1 || then_index == -1 || fi_index == -1){
        error_message();
    }

    char *constant = all_commands[then_index-1];
    char *operator = all_commands[then_index-2];

    // command between if and operator
    char *some_command[512];

    // get some_command 
    for (int i = 1; i < then_index-2; i++){
        some_command[i-1] = all_commands[i];
    }

    // NOTES:
    // execv("one", ["one", /0]);
    // cat batch_file | ./wish

    free(temp_line);
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

// if any error due to bad syntax from user, but don't exit(0)
void error_message_without_exit()
{
    char error_message[30] = "An error has occurred\n";
    write(STDERR_FILENO, error_message, strlen(error_message));
}
