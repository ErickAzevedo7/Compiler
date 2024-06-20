%{
#include <string>

%}

ESPACO [ \t]
DIGITO [0-9]
LETRA [A-Za-z_]

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}+("."{NUM}+)?
CHAR \'({LETRA}|{DIGITO})\'
BOOL ("True"|"False")
ID {LETRA}({LETRA}|{NUM})*

%%

"\n"		{}

{DELIM} 	{}

"main"		{return TK_MAIN;}

"if"        {yylval.label = yytext; return TK_IF;}
"else"      {yylval.label = yytext; return TK_ELSE;}
"while"     {yylval.label = yytext; return TK_WHILE;}

 /* variables types */
"int"		{return TK_TYPE_INT;}
"float"     {return TK_TYPE_FLOAT;}
"bool"      {return TK_TYPE_BOOL;}
"char"      {return TK_TYPE_CHAR;}

[(){}[\];,]	{ return *yytext; }

 /* arithmetic operators */
[+\-*/%]	{yylval.label = yytext; return *yytext; }

 /* relational operators */
[>\<]       {yylval.label = yytext; return *yytext; }
">="        {yylval.label = yytext; return TK_OP_GREATER_EQUAL; }
"<="        {yylval.label = yytext; return TK_OP_LESS_EQUAL; }
"=="        {yylval.label = yytext; return TK_OP_EQUAL; }
"!="        {yylval.label = yytext; return TK_OP_DIF; }

 /* logic operators */
[!]         {yylval.label = yytext; return *yytext; }
"&&"        {yylval.label = yytext; return TK_OP_AND; }
"||"        {yylval.label = yytext; return TK_OP_OR; }

"="		    { yylval.label = yytext; return '='; }

{NUM}		{ yylval.label = yytext; return TK_NUM; }
{BOOL}      { yylval.label = yytext; return TK_BOOL; }
{ID}		{ yylval.label = yytext; return TK_ID; }
{REAL}		{ yylval.label = yytext; return TK_REAL; }
{CHAR}      { yylval.label = yytext; return TK_CHAR; }
.			{ return *yytext; }

%%
