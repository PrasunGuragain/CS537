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

int main(int argc, char* argv[]){
    char cmd[100], command[100], *parameters[20];

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

        int pid = fork();
        if(pid!=0){
            wait(NULL); // if problems, look at wait_pid(), and wif_signal()
        }
        else{
            strcpy(cmd, "/usr/bin/");
            strcat(cmd, command);

            if (execv(cmd, parameters) == -1){ // execute command
                error_message();
            }
        }
    }
    return 0;
}
