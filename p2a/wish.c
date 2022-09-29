#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>

int read_command(char cmd[], char *par[]){
    char *array[100], *commandList;

    char *command = NULL;
    size_t bufsize = 0;
    getline(&command, &bufsize, stdin);

    commandList = strtok(command, " \n");

    int i = 0;
    // parse the line into words
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

int main(){
    char cmd[100], command[100], *parameters[20];

    while(1){
        prompt(); // display prompt on screen
        read_command(command, parameters); // read input from terminal
        if(fork()!=0){
            wait(NULL);
        }
        else{
            strcpy(cmd, "/bin/");
            strcat(cmd, command);
            if (execv(cmd, parameters) == -1){ // execute command
                char error_message[30] = "An error has occurred\n";
                write(STDERR_FILENO, error_message, strlen(error_message)); 
                exit(0);
            }
        }
        if (strcmp(command, "exit")==0){
            break;
        }
    }
    return 0;
}