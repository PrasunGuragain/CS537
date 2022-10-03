#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>

// reads user input
int read_command(char cmd[], char *par[]){
    char *array[100], *commandList;

    char *command = NULL;
    size_t bufsize = 0;
    getline(&command, &bufsize, stdin);

    commandList = strtok(command, " \n"); // remove end line \n

    // parse the line into words
    int i = 0;
    while(commandList != NULL){
        array[i] = strdup(commandList);
        i++;
        commandList = strtok(NULL, " \n");
    }
    
    // first word is the command
    strcpy(cmd, array[0]);

    // others are parameters
    for(int j = 0; j < i; j++){
        par[j] = array[j];
    }
    par[i] = NULL; // NULL-terminate the parameter list

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
    int i = 1;
    int j = 0;
    while(1){
        if (parameters[i] == NULL){
            break;
        }
        else{
            path[j] = parameters[i];
            (*num_of_path)++;
        }
        i++;
        j++;
    }
}

void execute(char *cmd, char **parameters, char *path, char *command, int *num_of_path){
    //for (int i = 0; i < *num_of_path; i++){
    int i = 0;
    int j = 0;
    while(i < *num_of_path){
        if(access(&path[j], X_OK) != -1){
            strcpy(cmd, &path[j]);
            strcat(cmd, "/");
            strcat(cmd, command);
            execv(cmd, parameters);
        }

        // +32 because path is a list of pointers (to list of char, so string)
        // so each space is 32 bits apart (because int is 32 bits)
        j += 32;

        i += 1; 
    }
    error_message();
}

int main(int argc, char* argv[]){
    char cmd[100], command[100], *parameters[20];
    
    char *path[100];
    path[0] = "/bin";

    int num_of_path = 1;

    while(1){
        prompt(); // display prompt on screen
        read_command(command, parameters); // read input from terminal

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

        int pid = fork();
        if(pid!=0){
            wait(NULL); // if problems, look at wait_pid(), and wif_signal()
        }
        else{
            execute(cmd, parameters, *path, command, &num_of_path);
        }
    }
    return 0;
}
