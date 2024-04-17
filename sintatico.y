%{
#include <iostream>
#include <map>
#include <string>
#include <sstream>
#include <stack>
#include <list>

#define YYSTYPE attributes

using namespace std;

int var_temp_qnt;

enum types{
	null = 0,
	t_int = 1,
	t_float = 2,
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
	string nickname;
}symbol;

typedef struct{
	types parameter1;
	types parameter2;
	string operation;
	types action;
	bool orderMatters;
}comparison;

map<string, comparison> comparisonTable;

list <symbol> global;

stack< list<symbol> > symbolTable;

int yylex(void);
void yyerror(string);
bool findSymbol(symbol);
symbol getSymbol(string);
void insertTable(string, types, string);
void existInTable(string, types);
void printScope();
void declareScopeVariable();
types findComparison(types, types, string);
string getEnum(types);
string gentempcode();
%}

%token TK_NUM TK_REAL
%token TK_MAIN TK_ID TK_TYPE_INT TK_TYPE_FLOAT
%token TK_END TK_ERROR

%start S

%left '+'
%left '*'

%%

S 			: TK_TYPE_INT TK_MAIN '(' ')' BLOCK
			{
				string code = "/*AERITH Compiler*/\n"
								"#include <iostream>\n"
								"#include <string.h>\n"
								"#include <stdio.h>\n"
								"int main(void) {\n";

				for(auto it = symbolTable.top().begin(); it != symbolTable.top().end(); ++it){
					code += "\t" + getEnum(it->type) + " " + it->nickname + "; " + "//" + it->name + "\n" ;
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

				insertTable($2.label, $$.type, gentempcode());
			}
			| TK_TYPE_FLOAT TK_ID ';'
			{
				$$.type = t_float;
				$$.label = "";
				$$.translation = "";

				insertTable($2.label, $$.type, gentempcode());
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
			| E '*' E
			{
				$$.translation = $1.translation + $3.translation + "\t";

				if($1.type != $3.type){
					symbol temp;
					temp.name = gentempcode();
					temp.type = findComparison($1.type, $3.type, "*");
					$$.type = temp.type;
					$$.label = gentempcode();

					if($1.type != temp.type){
						$$.translation += temp.name + " = " + "(" + getEnum(temp.type) + ") " + $1.label + ";\n" + "\t";
						$$.translation += $$.label + " = " + temp.name + " * " + $3.label + ";\n";
						insertTable(temp.name, temp.type, temp.name);
					}
					else{
						$$.translation += temp.name + " = " + "(" + getEnum(temp.type) + ") " + $3.label + ";\n" + "\t";
						$$.translation += $$.label + " = " + $1.label + " * " + temp.name + ";\n";
						insertTable(temp.name, temp.type, temp.name);
					}
				}
				else{
					$$.label = gentempcode();
					$$.type = $1.type;
					$$.translation += $$.label + " = " + $1.label + " * " + $3.label + ";\n";
				}

				insertTable($$.label, $$.type, $$.label);
			}
			| TK_ID '=' E
			{
				symbol id = getSymbol($1.label);

				$$.translation = $1.translation + $3.translation + "\t" + id.nickname + " = " + $3.label + ";\n";

				existInTable($1.label, $1.type);
			}
			| TK_NUM
			{
				$$.label = gentempcode();
				$$.translation = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.type = t_int;

				insertTable($$.label, $$.type, $$.label);
			}
			| TK_REAL
			{
				$$.label = gentempcode();
				$$.translation = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.type = t_float;

				insertTable($$.label, $$.type, $$.label);
			}
			| TK_ID
			{
				symbol variable = getSymbol($1.label);
				$$.label = gentempcode();
				$$.translation = "\t" + $$.label + " = " + variable.nickname + ";\n";
				$$.type = variable.type;

				existInTable($1.label, $1.type);

				

				insertTable($$.label, $$.type, $$.label);
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

	comparisonTable["floatCast"] = {t_int, t_float, "*", t_float, 0};

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

symbol getSymbol(string name){
	symbol variable;

	for(auto it = symbolTable.top().begin(); it != symbolTable.top().end(); ++it){
		if(it->name == name){
			return *it;
		}	
	}

	return variable;
}

void printScope(){
	for(auto it = symbolTable.top().begin(); it != symbolTable.top().end(); ++it){
		cout << it->name << endl;
		cout << it->type << endl;
		cout << endl;
	}

	return;
}

void declareScopeVariable(){
	for(auto it = symbolTable.top().begin(); it != symbolTable.top().end(); ++it){
		
	}
}

string getEnum(types type){
	if(type == t_int)
		return "int";
	else if(type == t_float)
		return "float";
	return "";
}

void insertTable(string name, types type, string nickname){
	symbol variable;
	variable.name = name;
	variable.type = type;
	variable.nickname = nickname;

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

types findComparison(types parameter1, types parameter2, string operation){
	for(auto it = comparisonTable.begin(); it != comparisonTable.end(); ++it){	
		if(it->second.operation == operation && parameter1 == it->second.parameter1 &&  parameter2 == it->second.parameter2){
			return it->second.action;
		}
		if(it->second.operation == operation && parameter1 == it->second.parameter2 &&  parameter2 == it->second.parameter1){
			return it->second.action;
		}
	}
	return null;
}
