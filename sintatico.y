%{
#include <iostream>
#include <string>
#include <sstream>
#include <stack>
#include <list>

#define YYSTYPE attributes

using namespace std;

int var_temp_qnt;

enum types{
	t_int = 0,
	t_float = 1,
};

struct attributes
{
	string label;
	string translation;
	types type;
};

typedef struct{
	string name;
	types type;
}symbol;

list <symbol> symbolTable;

stack< list<symbol> > scope;

int yylex(void);
void yyerror(string);
string gentempcode();
%}

%token TK_NUM
%token TK_MAIN TK_ID TK_TYPE_INT
%token TK_END TK_ERROR

%start S

%left '+'

%%

S 			: TK_TYPE_INT TK_MAIN '(' ')' BLOCK
			{
				string code = "/*AERITH Compiler*/\n"
								"#include <iostream>\n"
								"#include <string.h>\n"
								"#include <stdio.h>\n"
								"int main(void) {\n";
								
				code += $5.translation;
								
				code += 	"\treturn 0;"
							"\n}";

				cout << code << endl;
			}
			;

BLOCK		: '{' COMANDS '}'
			{
				$$.translation = $2.translation;
			}
			;

COMANDS	: COMAND COMANDS
			{
				$$.translation = $1.translation + $2.translation;
			}
			|
			{
				$$.translation = "";
			}
			;

COMAND 	: E ';'
			{
				$$ = $1;
			}
			| TK_TYPE_INT TK_ID ';'
			{
				$$.type = t_int;
				$$.label = "";
				$$.translation = "";


			}
			;

E 			: E '+' E
			{
				$$.label = gentempcode();
				$$.translation = $1.translation + $3.translation + "\t" + $$.label + 
					" = " + $1.label + " + " + $3.label + ";\n";
			}
			| E '-' E
			{
				$$.label = gentempcode();
				$$.translation = $1.translation + $3.translation + "\t" + $$.label + 
					" = " + $1.label + " - " + $3.label + ";\n";
			}
			| TK_ID '=' E
			{
				$$.translation = $1.translation + $3.translation + "\t" + $1.label + " = " + $3.label + ";\n";
			}
			| TK_NUM
			{
				$$.label = gentempcode();
				$$.translation = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			| TK_ID
			{
				$$.label = gentempcode();
				$$.translation = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			;

%%

#include "lex.yy.c"

int yyparse();

string gentempcode()
{
	var_temp_qnt++;
	return "t" + to_string(var_temp_qnt);
}

int main(int argc, char* argv[])
{
	symbol test;

	test.name = "a";
	test.type = t_int;

	symbolTable.push_back(test);
	scope.push(symbolTable);

	for(auto it = scope.top().begin(); it != scope.top().end(); ++it){
		cout << it->name << endl;
		cout << it->type << endl;
	}

	var_temp_qnt = 0;

	yyparse();

	return 0;
}

void yyerror(string MSG)
{
	cout << MSG << endl;
	exit (0);
}				
