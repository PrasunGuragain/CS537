#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <sys/stat.h>

void redirection(char *commandList, char **path, int num_of_path);
void handel_fork(char **parameters, char **path, char* command, int num_of_path, int redirecting, char *file_name);
void if_then(char *command);


// reads user input
int read_command(char cmd[], char *par[], char **path, int num_of_path){
    char *array[100], *commandList;
    commandList = malloc(100*sizeof(char));

    char *command;
    command = malloc(256*sizeof(char));
    size_t bufsize = 0;
    getline(&command, &bufsize, stdin);

    // if_then
    //printf("command[0]: %c, command[1]: %c\n", command[0], command[1]);
    if (command[0] == 'i' && command[1] == 'f'){
        if_then(command);
        return -1;
    }

    // Redirection
    char * ret;
    ret = strchr(command, '>');
    if (ret != NULL){
        redirection(command, path, num_of_path);
        return -1;
    }

    // parse the line into words
    int i = 0;
    commandList = strtok(command, " \t\n");
    while(commandList != NULL){
        array[i] = strdup(commandList);
        i++;
        commandList = strtok(NULL, " \t\n");
    }

    // first word is the command
    strcpy(cmd, array[0]);

    // others are parameters
    int j = 0;
    while (j < i){
        par[j] = array[j];
        j++;
    }

    // need "/0" right after the end of parameters
    par[i] = NULL;

    free(commandList);
    return 0;
}

// clears screen then wish shell starts
void prompt(){
    static int first_time = 1;

    // clear screen if at the beginning
    if (first_time){
        const char* clear_screen_ansi = " \e[1;1H\e[2J";
        write(STDERR_FILENO, clear_screen_ansi, 12);
        first_time = 0;
    }

    printf("wish> ");
}

// if any error due to bad syntax from user
void error_message(){
    char error_message[30] = "An error has occurred\n";
    write(STDERR_FILENO, error_message, strlen(error_message));
    exit(0);
}

void cd_command(char *par){
    if(chdir(par) != 0){
        error_message();
    }
}

void path_command(char **path, char **parameters, int *num_of_path){
    int i = 0;
    while(1){
        if (parameters[i] == NULL){
            break;
        }
        else{
            path[i] = parameters[i];
            (*num_of_path)++;
        }
        i++;
    }
}

void execute(char **parameters, char *path, char *command, int *num_of_path){
    char *cmd;
    int i = 0;
    int j = 0;
    while(i < *num_of_path){
        if(access(&path[j], X_OK) != -1){
            strcpy(cmd, &path[j]);
            strcat(cmd, "/");
            strcat(cmd, command);
            execv(cmd, parameters);
        }

        // I believe +32 because int is 32 bit and path is a list of pointers to the first element of a string
        j += 32;

        i += 1; 
    }
    error_message();
}

void redirection(char *line, char **path, int num_of_path){
    // Get everything to left of ">" (operation)
    char *params_str = strtok(line, ">");

    // Get everything to right of ">" (file name)
    char *file_name = strtok(NULL, ">");
    file_name = strtok(file_name, " \n");

    // Stores all the parameters. If ls -l, this will store -l
    char *all_params[100];

    // the command. If ls -l, this will store ls
    char *current = strtok(params_str, " ");
    char *command = current;
    all_params[0] = command;

    int i = 1;
    while(current){
        current = strtok(NULL, " ");
        all_params[i] = current;
        i++;
    }

    // I was wrong about parameters. If user type ls -l, parameters should be:
    // [ls, -1, null(/0)] and command should be: "ls"
    handel_fork(all_params, path, command, num_of_path, 1, file_name);
}

void handel_fork(char **parameters, char **path, char* command, int num_of_path, int redirecting, char *file_name){
    int pid = fork();
    if(pid!=0){
        wait(&pid); // if problems, look at wait_pid(), and wif_signal()
    }
    else{
        if (redirecting == 1){
            // open file
            int fd = open(file_name, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);

            // make stdout go to file
            dup2(fd, 1);

            // make stderr go to file
            dup2(fd, 2);

            close(fd);
        }
        execute(parameters, *path, command, &num_of_path);
    }
}

void if_then(char *line){
    printf("In if then...\n");

    char *temp_line = malloc(sizeof(char)*100);
    strcpy(temp_line, line);

    // strstr() will point to 't' in the first then, so "then" and after
    char *then_and_after = strstr(temp_line, "then");

    char *array[100];
    char *current = strtok(line, " ");

    int i = 0;
    while(current){
        array[i] = current;
        current = strtok(NULL, " ");
        i++;
    }

    

    free(temp_line);
}

int main(int argc, char* argv[]){
    char command[100], *parameters[100];
    
    char *path[100];
    path[0] = "/bin";

    int num_of_path = 1;

    while(1){
        prompt(); // display prompt on screen
        int read_return = read_command(command, parameters, path, num_of_path); // read input from terminal

        // if done redirection or if_then command, don't handel_fork() again
        if (read_return  == -1){
            continue;
        }

        if (strcmp(command, "exit") == 0){
            exit(0);
        }
        else if (strcmp(command, "cd") == 0){
            cd_command(parameters[1]);
            continue;
        }
        else if(strcmp(command, "path") == 0){
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
