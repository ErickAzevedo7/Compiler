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
	t_bool = 3,
	t_char = 4,
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
	string address;
	bool istemp;
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
void insertTable(string, types, string, bool);
void existInTable(string, types);
void printScope();
types findComparison(types, types, string);
string getEnum(types);
string gentempcode();
attributes binaryOperator(attributes, attributes, attributes);
attributes relationalOperator(attributes, attributes, attributes);
%}

%token TK_NUM TK_REAL TK_BOOL TK_CHAR
%token TK_MAIN TK_ID TK_TYPE_INT TK_TYPE_FLOAT TK_TYPE_BOOL TK_TYPE_CHAR
%token TK_OP_GREATER_EQUAL TK_OP_LESS_EQUAL TK_OP_EQUAL TK_OP_DIF
%token TK_OP_AND TK_OP_OR
%token TK_END TK_ERROR

%start S

%left TK_OP_OR
%left TK_OP_AND
%left TK_OP_EQUAL TK_OP_DIF
%left '>' '<' TK_OP_GREATER_EQUAL TK_OP_LESS_EQUAL
%left '+' '-'
%left '*' '/' '%'
%left '!'
%left '(' ')'

%%

S 			: TK_TYPE_INT TK_MAIN '(' ')' BLOCK
			{
				string code = "/*AERITH Compiler*/\n"
								"#include <iostream>\n"
								"#include <string.h>\n"
								"#include <stdio.h>\n"
								"#define bool int\n"
								"#define True 1\n"
								"#define False 0\n"
								"int main(void) {\n";

				for(auto it = symbolTable.top().begin(); it != symbolTable.top().end(); ++it){
					code += "\t" + getEnum(it->type) + " " + it->address + "; " + "//" + it->name + "\n" ;
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

COMANDS		: COMAND COMANDS
			{
				$$.translation = $1.translation + $2.translation;
			}
			|
			{
				$$.translation = "";
			}
			;

TYPE 		: TK_TYPE_INT
			{
				$$.type = t_int;
				$$.label = "";
				$$.translation = "";
			}
			| TK_TYPE_FLOAT
			{
				$$.type = t_float;
				$$.label = "";
				$$.translation = "";
			}
			| TK_TYPE_BOOL
			{
				$$.type = t_bool;
				$$.label = "";
				$$.translation = "";				
			}
			| TK_TYPE_CHAR
			{
				$$.type = t_char;
				$$.label = "";
				$$.translation = "";				
			}
			;

COMAND 		: E ';'
			{
				$$ = $1;
			}
			| TYPE TK_ID ';'
			{
				$$.type = $1.type;
				$$.label = "";
				$$.translation = "";

				insertTable($2.label, $$.type, gentempcode(), false);
			}
			;

E 			: '(' E ')'
			{
				$$.type = $2.type;
				$$.label = $2.label;
				$$.translation = $2.translation;
			}
			| '(' TYPE ')' E
			{
				$$.type = $2.type;
				$$.label = gentempcode();

				$$.translation = $4.translation + "\t" + $$.label + " = " + "(" + getEnum($2.type) + ") " + $4.label + ";\n";

				insertTable("", $$.type, $$.label, true);	
			}
			| E '+' E
			{
				$$ = binaryOperator($1, $2, $3);
			}
			| E '-' E
			{
				$$ = binaryOperator($1, $2, $3);
			}
			| E '*' E
			{
				$$ = binaryOperator($1, $2, $3);
			}
			| E '/' E
			{
				$$ = binaryOperator($1, $2, $3);
			}
			| E '%' E
			{
				$$ = binaryOperator($1, $2, $3);
			}
			| E '>' E
			{
				$$ = relationalOperator($1, $2, $3);
			}
			| E '<' E
			{
				$$ = relationalOperator($1, $2, $3);
			}
			| E TK_OP_GREATER_EQUAL E
			{
				$$ = relationalOperator($1, $2, $3);
			}
			| E TK_OP_LESS_EQUAL E
			{
				$$ = relationalOperator($1, $2, $3);
			}
			| E TK_OP_EQUAL E
			{
				$$ = relationalOperator($1, $2, $3);
			}
			| E TK_OP_DIF E
			{
				$$ = relationalOperator($1, $2, $3);
			}
			| E TK_OP_AND E
			{
				$$ = binaryOperator($1, $2, $3);
			}
			| E TK_OP_OR E
			{
				$$ = binaryOperator($1, $2, $3);
			}
			|'!' E
			{
				types resultType = findComparison($2.type, null, $1.label);

				if(resultType == null){
					yyerror("não é possivel fazer a operação de " + $1.label + " com o tipo " + getEnum($2.type));
				}

				$$.translation = $2.translation + "\t";

				$$.label = gentempcode();
				$$.type = resultType;
				$$.translation += $$.label + " = " + $1.label + $2.label + ";\n";

				insertTable("", $$.type, $$.label, true);
			}
			| TK_ID '=' E
			{
				symbol id = getSymbol($1.label);

				$$.label = id.address;
				$$.type = id.type;
				$$.translation = $1.translation + $3.translation + "\t" + id.address + " = " + $3.label + ";\n";
				
				existInTable($1.label, $1.type);

				if(id.type != $3.type){
					yyerror("Atribuição de um tipo " + getEnum($3.type) + " a uma variavel do tipo " + getEnum(id.type));
				}
			}
			| TK_NUM
			{
				$$.label = gentempcode();
				$$.translation = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.type = t_int;

				insertTable("", $$.type, $$.label, true);
			}
			| TK_REAL
			{
				$$.label = gentempcode();
				$$.translation = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.type = t_float;

				insertTable("", $$.type, $$.label, true);
			}
			| TK_BOOL
			{
				$$.label = gentempcode();
				$$.translation = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.type = t_bool;

				insertTable("", $$.type, $$.label, true);
			}
			| TK_CHAR
			{
				$$.label = gentempcode();
				$$.translation = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.type = t_char;

				insertTable("", $$.type, $$.label, true);
			}
			| TK_ID
			{
				symbol id = getSymbol($1.label);
				$$.label = id.address;
				$$.translation = "";
				$$.type = id.type;

				existInTable($1.label, $1.type);
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

	/* adding operators type rules */
	comparisonTable["* (int-int)"] = {t_int, t_int, "*", t_int, 0};
	comparisonTable["* (float-float)"] = {t_float, t_float, "*", t_float, 0};
	comparisonTable["* (int-float)"] = {t_int, t_float, "*", t_float, 0};
	comparisonTable["/ (int-int)"] = {t_int, t_int, "/", t_int, 0};
	comparisonTable["/ (float-float)"] = {t_float, t_float, "/", t_float, 0};
	comparisonTable["/ (int-float)"] = {t_int, t_float, "/", t_float, 0};
	comparisonTable["% (int-int)"] = {t_int, t_int, "%", t_int, 0};
	comparisonTable["% (float-float)"] = {t_float, t_float, "%", t_float, 0};
	comparisonTable["% (int-float)"] = {t_int, t_float, "%", t_float, 0};
	comparisonTable["+ (int-int)"] = {t_int, t_int, "+", t_int, 0};
	comparisonTable["+ (float-float)"] = {t_float, t_float, "+", t_float, 0};
	comparisonTable["+ (int-float)"] = {t_int, t_float, "+", t_float, 0};
	comparisonTable["- (int-int)"] = {t_int, t_int, "-", t_int, 0};
	comparisonTable["- (float-float)"] = {t_float, t_float, "-", t_float, 0};
	comparisonTable["- (int-float)"] = {t_int, t_float, "-", t_float, 0};
	comparisonTable["> (int-int)"] = {t_int, t_int, ">", t_int, 0};
	comparisonTable["> (float-float)"] = {t_float, t_float, ">", t_float, 0};
	comparisonTable["> (int-float)"] = {t_int, t_float, ">", t_float, 0};
	comparisonTable["< (int-int)"] = {t_int, t_int, "<", t_int, 0};
	comparisonTable["< (float-float)"] = {t_float, t_float, "<", t_float, 0};
	comparisonTable["< (int-float)"] = {t_int, t_float, "<", t_float, 0};
	comparisonTable[">= (int-int)"] = {t_int, t_int, ">=", t_int, 0};
	comparisonTable[">= (float-float)"] = {t_float, t_float, ">=", t_float, 0};
	comparisonTable[">= (int-float)"] = {t_int, t_float, ">=", t_float, 0};
	comparisonTable["<= (int-int)"] = {t_int, t_int, "<=", t_int, 0};
	comparisonTable["<= (float-float)"] = {t_float, t_float, "<=", t_float, 0};
	comparisonTable["<= (int-float)"] = {t_int, t_float, "<=", t_float, 0};
	comparisonTable["== (int-int)"] = {t_int, t_int, "==", t_int, 0};
	comparisonTable["== (float-float)"] = {t_float, t_float, "==", t_float, 0};
	comparisonTable["== (int-float)"] = {t_int, t_float, "==", t_float, 0};
	comparisonTable["== (char-char)"] = {t_char, t_char, "==", t_char, 0};
	comparisonTable["== (bool-bool)"] = {t_bool, t_bool, "==", t_bool, 0};
	comparisonTable["!= (int-int)"] = {t_int, t_int, "!=", t_int, 0};
	comparisonTable["!= (float-float)"] = {t_float, t_float, "!=", t_float, 0};
	comparisonTable["!= (int-float)"] = {t_int, t_float, "!=", t_float, 0};
	comparisonTable["!= (char-char)"] = {t_char, t_char, "!=", t_char, 0};
	comparisonTable["!= (bool-bool)"] = {t_bool, t_bool, "!=", t_bool, 0};
	comparisonTable["&& (bool-bool)"] = {t_bool, t_bool, "&&", t_bool, 0};
	comparisonTable["|| (bool-bool)"] = {t_bool, t_bool, "||", t_bool, 0};
	comparisonTable["! (bool)"] = {t_bool, null, "!", t_bool, 0};

	symbolTable.push(main);

	var_temp_qnt = 0;

	yyparse();

	printScope();

	return 0;
}

void yyerror(string MSG)
{
	cout << MSG << endl;
	exit (0);
}

bool findSymbol(symbol variable){
	for(auto it = symbolTable.top().begin(); it != symbolTable.top().end(); ++it){
		if(it->istemp == false && it->name == variable.name){
			return true;
		}	
	}

	return false;
}

symbol getSymbol(string name){
	symbol variable;

	for(auto it = symbolTable.top().begin(); it != symbolTable.top().end(); ++it){
		if(it->istemp == false && it->name == name){
			return *it;
		}	
	}

	return variable;
}

void printScope(){
	for(auto it = symbolTable.top().begin(); it != symbolTable.top().end(); ++it){
		cout << it->name << " | " << getEnum(it->type) << " | " << it->address <<  " | " << it->istemp << endl;
		cout << endl;
	}

	return;
}

string getEnum(types type){
	if(type == t_int)
		return "int";
	else if(type == t_float)
		return "float";
	else if(type == t_bool)
		return "bool";
	else if(type == t_char)
		return "char";
	return "";
}

void insertTable(string name, types type, string address, bool istemp){
	symbol variable;
	variable.name = name;
	variable.type = type;
	variable.address = address;
	variable.istemp = istemp;

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

attributes binaryOperator(attributes $1, attributes $2, attributes $3){
	types resultType = findComparison($1.type, $3.type, $2.label);

	if(resultType == null){
		yyerror("não é possivel fazer a operação de " + $2.label + " com os tipos " + getEnum($1.type) + " e " + getEnum($3.type));
	}

	attributes $$;

	$$.translation = $1.translation + $3.translation + "\t";

	if($1.type != $3.type){
		symbol temp;
		temp.name = gentempcode();
		temp.type = resultType;
		$$.type = temp.type;
		$$.label = gentempcode();

		if($1.type != temp.type){
			$$.translation += temp.name + " = " + "(" + getEnum(temp.type) + ") " + $1.label + ";\n" + "\t";
			$$.translation += $$.label + " = " + temp.name + " " + $2.label + " " + $3.label + ";\n";
			insertTable("", temp.type, temp.name, true);
		}
		else{
			$$.translation += temp.name + " = " + "(" + getEnum(temp.type) + ") " + $3.label + ";\n" + "\t";
			$$.translation += $$.label + " = " + $1.label + " " + $2.label + " " + temp.name + ";\n";
			insertTable("", temp.type, temp.name, true);
		}
	}
	else{
		$$.label = gentempcode();
		$$.type = resultType;
		$$.translation += $$.label + " = " + $1.label + " " + $2.label + " " + $3.label + ";\n";
	}

	insertTable("", $$.type, $$.label, true);

	return $$;
}

attributes relationalOperator(attributes $1, attributes $2, attributes $3){
	types resultType = findComparison($1.type, $3.type, $2.label);

	if(resultType == null){
		yyerror("não é possivel fazer a operação de " + $2.label + " com os tipos " + getEnum($1.type) + " e " + getEnum($3.type));
	}

	attributes $$;

	$$.translation = $1.translation + $3.translation + "\t";

	if($1.type != $3.type){
		symbol temp;
		temp.name = gentempcode();
		temp.type = resultType;
		$$.type = t_bool;
		$$.label = gentempcode();

		if($1.type != temp.type){
			$$.translation += temp.name + " = " + "(" + getEnum(temp.type) + ") " + $1.label + ";\n" + "\t";
			$$.translation += $$.label + " = " + temp.name + " " + $2.label + " " + $3.label + ";\n";
			insertTable("", temp.type, temp.name, true);
		}
		else{
			$$.translation += temp.name + " = " + "(" + getEnum(temp.type) + ") " + $3.label + ";\n" + "\t";
			$$.translation += $$.label + " = " + $1.label + " " + $2.label + " " + temp.name + ";\n";
			insertTable("", temp.type, temp.name, true);
		}
	}
	else{
		$$.label = gentempcode();
		$$.type = t_bool;
		$$.translation += $$.label + " = " + $1.label + " " + $2.label + " " + $3.label + ";\n";
	}

	insertTable("", $$.type, $$.label, true);

	return $$;
}
