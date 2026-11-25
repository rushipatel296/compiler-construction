%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
char* variable_table[1000];
int var_count = 0;
int check_keyword(const char* str) {
	const char* keywords[] = {"int", "char", "if", "else", "while", "for", "main", "begin", "end", "print", "scan", "program", "VarDecl", "inc", "dec", "to", "do"};
	for (int i = 0; i < (sizeof(keywords)/sizeof(keywords[0])); i++) {
        	if (strcmp(str, keywords[i]) == 0) {
        		return 1;
        	}
    	}
	return 0;
}
int check_if_identifier(const char* str) {
    	if (isdigit(str[0]) || str[0] == '_') {
    		return 0;
    	}
    	int underscore_cnt = 0;
    	for (int i = 0; str[i] != '\0'; i++) {
        	if (str[i] == '_') {
        		underscore_cnt++;
        	}
        	if (!islower(str[i]) && !isdigit(str[i]) && str[i] != '_') {
            		return 0;
        	}
    	}
    	if (underscore_cnt > 1) {
        	return 0;
    	}
    return 1;
}
int check_data_type(const char* str) {
	if (strcmp(str, "int") == 0 || strcmp(str, "char") == 0) {
		return 1;
	} else {
		return 0;
	}
}
int is_declared(char* var) {
	for (int i = 0; i < var_count; i++) {
		if (strcmp(variable_table[i], var) == 0) {
			return 1;
		}
    	}
    	return 0;
}
void add_to_table(char* var) {
	if (var_count < 1000) {
		variable_table[var_count++] = strdup(var);
	}
}
int count_ats(const char* str) {
	int at_count = 0;
	for (int i = 0; str[i] != '\0'; i++) {
        	if (str[i] == '@') {
	        	at_count++;
        	}
    	}
	return at_count;
}
int count_variables(const char* str) {
	int count = 0;
	char* copy = strdup(str);
    	char* token = strtok(copy, ",");
    	while (token) {
    		count++;
    		token = strtok(NULL, ",");
        	if (token == NULL) break; 
        	int length = strlen(token);
		for (int i = 0 ; i < length ; i++) {
       			if (token[i] == ')') {
       				count--;
       			}
       		}
	}
    	return count;
}
int count_commas(const char* str) {
	int comma_count = 0;
	for (int i = 0; str[i] != '\0'; i++) {
        	if (str[i] == ',') {
	        	comma_count++;
        	}
    	}
    	return comma_count;
}
int in_var_decl = 0;
int decl_start_flag = 0;
int decl_end_flag = 0;
%}
%option noyywrap
DIGIT [0-9]
ID [a-zA-Z0-9_!@#$%&*]*
%%
[ \t\n]+ {;} // Empty spaces, newline
"//".* {;} // Single-line comment
"/*"([^*]|\*+[^*/])*\*+"/" {;} // Multi-line comment
"begin"|"program" {printf("%s Keyword\n", yytext);}
"VarDecl" {decl_start_flag = 1; printf("%s Keyword\n", yytext);}
"end" {if (in_var_decl) {in_var_decl = 0; decl_end_flag = 1;} printf("%s Keyword\n", yytext);}
"if"|"do"|"to"|"else"|"while"|"for"|"main"|"int"|"char"|"inc"|"dec" { printf("%s Keyword\n", yytext); }
":="|"+="|"-="|"*="|"/="|"%=" {printf("%s Assignment operator\n", yytext);}
">="|"<="|"<>"|">"|"<"|"=" {printf("%s Relational operator\n", yytext);}
"+"|"-"|"*"|"/"|"%" {printf("%s Arithmetic Operator\n", yytext);}
"("|")"|","|";" {printf("%s Separator\n", yytext);}
":"  {if (decl_start_flag) {in_var_decl = 1; decl_start_flag = 0;} printf("%s Separator\n", yytext);}
"{"|"}"|"@"|"'"|"["|"]" {printf("%s Separator\n", yytext);}
{DIGIT}+ {printf("%s Array Length\n", yytext);}
"print"[ \t]*"("[^;]*";" {
	char* print_stmt = strdup(yytext + 7);
	print_stmt[strlen(print_stmt) - 2] = '\0';
    	char* format_str = strtok(print_stmt, "\"");
    	char* variable_list = strtok(NULL, "");
    	int at_count = count_ats(format_str);
    	if (!variable_list) {
    		if (!at_count) {
    			printf("%s Valid output statement\n", yytext);
    		} else {
    			printf("%s Error: invalid output statement\n", yytext);
    		}
    	} else {
        	int var_count = count_variables(variable_list);
        	if (at_count != var_count) {
        		printf("%s Error: invalid output statement\n", yytext);
        	} else {
            		printf("%s Valid output statement\n", yytext);
        	}
    	}
}
"scan"[ \t]*"("[^)]*");" {
	char* scan_stmt = strdup(yytext + 6);
	scan_stmt[strlen(scan_stmt) - 2] = '\0';
    	char* format_str = strtok(scan_stmt, "\"");
    	char* variable_list = strtok(NULL, "");
    	int floog = 1;
    	for (int i = 0 ; i < strlen(format_str) ; i++) {
    		if (format_str[i] != ' ' && format_str[i] != '@' && format_str[i] != ',') {
			floog = 0;
		}
    	}
    	if (format_str && variable_list && floog) {
    		int comma_count = count_commas(format_str);
        	int at_count = count_ats(format_str);
        	int var_count = count_variables(variable_list);
        	if (at_count != var_count || at_count != comma_count+1) {
        		printf("%s Error: invalid input statement\n", yytext);
        	} else {
        		printf("%s Valid input statement\n", yytext);
        	}
    	} else {
        		printf("%s Error: invalid input statement\n", yytext);
    	}
}
"("{DIGIT}+[ \t]*","[ \t]*{DIGIT}+")" {
	char *s = strdup(yytext);
    	int val, base;
    	int numMatched = sscanf(s, "(%d , %d)", &val, &base);
    	if (numMatched != 2) numMatched = sscanf(s, "(%d,%d)", &val, &base);
    	if (numMatched == 2) {
        	if (base != 2 && base != 8 && base != 10) {
	        	printf("%s Error: invalid integer constant\n", yytext);
        	} else {
            		char first_num[100]; // to store number before comma 
            		sscanf(s, "(%[^,],", first_num); // extracts 1st number 
            		char *ptr = first_num; // iterates number part
            		while (*ptr && isspace(*ptr)) ptr++; // removes spaces if any
            		int valid = 1; // valid flag
            		for (int i = 0 ; ptr[i] != '\0' && !isspace(ptr[i]); i++) {
                		char c = ptr[i];
                		if (base == 2 && (c != '0' && c != '1')) {valid = 0; break;}
                		if (base == 8 && (c < '0' || c > '7')) {valid = 0; break;}
                		if (base == 10 && !isdigit(c)) {valid = 0; break;}
            		}
           		if (!valid) {
                		printf("%s Error: invalid integer constant\n", yytext);
                	} else {
                		printf("%s Integer constant\n", yytext);
                	}
        	}
    	} else {
        	printf("%s Error: invalid integer constant\n", yytext);
    	}
}
{ID} {
	if (!check_if_identifier(yytext)) {
	        printf("%s Error: invalid identifier\n", yytext);
    	} else if (check_keyword(yytext)) {
		printf("%s Error: Keyword is used as an identifier\n", yytext);
    	} else {
        	if (in_var_decl) {
        		if (is_declared(yytext)) {
	                	printf("%s Error: identifier already declared\n", yytext);
        		} else {
                		add_to_table(yytext);
            			printf("%s Identifier\n", yytext);
            		}
        	} else {
        		printf("%s Identifier\n", yytext);
        	}
    	}
}
"("{ID}","[ \t]*{ID}")" {
	char* stmt = strdup(yytext);
    	char* var_name = strtok(stmt, ",");
    	char* type = strtok(NULL, ")");
    	if (var_name && type) {
        	var_name += 1; // Remove opening '('
	        type += strspn(type, " \t"); // Remove leading whitespace
        	printf("( Separator\n");
        	if (check_keyword(var_name)) {
            		printf("%s Error: Keyword is used as an identifier\n", var_name);
        	} else if (!check_if_identifier(var_name)) {
            		printf("%s Error: invalid identifier\n", var_name);
		} else if (is_declared(var_name)) {
	                printf("%s Error: identifier already declared\n", var_name);
        	} else { // Valid identifier
        		add_to_table(var_name);
        	   	printf("%s Identifier\n", var_name);
        	}
	        printf(", Separator\n");
        	if (!check_data_type(type)) {
        		printf("%s Error: invalid data type\n", type);
        	} else {
        		printf("%s Keyword\n", type);
        	}
        	printf(") Separator\n");
    	} else {
        	printf("%s Error: invalid variable declaration\n", yytext);
    	}
}
. {printf("%s Unrecognized token\n", yytext);}
%%
int main(int argc, char **argv) {
	const char *path = argc > 1 ? argv[1] : "input.txt";
	yyin = fopen(path, "r");
	if (!yyin) {
		perror(path);
		return 1;
	}
	printf("LEXEME\tTOKEN TYPE\n");
	printf("------------------\n");
	yylex();
	fclose(yyin);
	return 0;
}
