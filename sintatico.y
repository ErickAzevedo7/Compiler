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
	t_bool = 3,
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

list <symbol> global;

stack< list<symbol> > symbolTable;

int yylex(void);
void yyerror(string);
bool findSymbol(symbol);
void insertTable(string, types);
void existInTable(string, types);
void printScope();
void declareScopeVariable();
string getEnum(types);
string gentempcode();
%}

%token TK_NUM TK_REAL TK_BOOL
%token TK_MAIN TK_ID TK_TYPE_INT TK_TYPE_FLOAT TK_TYPE_BOOL
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
								"#define BOOL int\n"
								"int main(void) {\n";

				for(auto it = symbolTable.top().begin(); it != symbolTable.top().end(); ++it){
					code += "\t" + getEnum(it->type) + it->name + "\n" ;
				}
								
				code += "\n" + $5.translation;
								
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

				insertTable($2.label, $$.type);
			}
			| TK_TYPE_FLOAT TK_ID ';'
			{
				$$.type = t_float;
				$$.label = "";
				$$.translation = "";

				insertTable($2.label, $$.type);
			}
			| TK_TYPE_BOOL TK_ID ';'
			{
				$$.type = t_bool;
				$$.label = "";
				$$.translation = "";

				insertTable($2.label, $$.type);
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

				existInTable($1.label, $1.type);
			}
			| TK_NUM
			{
				$$.label = gentempcode();
				$$.translation = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.type = t_int;

				insertTable($$.label, $$.type);
			}
			| TK_REAL
			{
				$$.label = gentempcode();
				$$.translation = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.type = t_float;

				insertTable($$.label, $$.type);
			}
			| TK_ID
			{
				$$.label = gentempcode();
				$$.translation = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.type = $1.type;

				existInTable($1.label, $1.type);

				insertTable($$.label, $$.type);
			}
			| TK_BOOL
			{
				$$.label = gentempcode();
				$$.translation = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.type = $1.type;

				existInTable($1.label, $1.type);

				insertTable($$.label, $$.type);
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
	symbolTable.push(global);
	list <symbol> main;

	symbolTable.push(main);

	var_temp_qnt = 0;

	yyparse();

	return 0;
}

void yyerror(string MSG)
{
	cout << MSG << endl;
	exit (0);
}

bool findSymbol(symbol variable){

	for(auto it = symbolTable.top().begin(); it != symbolTable.top().end(); ++it){
		if(it->name == variable.name){
			return true;
		}	
	}

	return false;
}

void printScope(){
	for(auto it = symbolTable.top().begin(); it != symbolTable.top().end(); ++it){
		cout << it->name << endl;
		cout << it->type << endl;
	}

	return;
}

void declareScopeVariable(){
	for(auto it = symbolTable.top().begin(); it != symbolTable.top().end(); ++it){
		
	}
}

string getEnum(types type){
	if(type == t_int)
		return "int ";
	else if(type == t_float)
		return "float ";
	else if(type == t_bool)
		return "bool ";
}

void insertTable(string name, types type){
	symbol variable;
	variable.name = name;
	variable.type = type;

	if(!findSymbol(variable)){
		symbolTable.top().push_back(variable);

	}
	else{
		yyerror("A Variável " + variable.name + " ja foi declarada.");
	}
}

void existInTable(string name, types type){
	symbol variable;
	variable.name = name;
	variable.type = type;

	if(!findSymbol(variable)){
		yyerror("A Variável " + variable.name + " não foi declarada");
	}
}

int isBool(char c){
	return (c == 'TRUE' | c == 'FALSE');
}
