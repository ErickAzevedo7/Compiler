%{
#include <string>

%}

ESPACO [ \t]
DIGITO [0-9]
LETRA [A-Za-z_]

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}+("."{NUM}+)?
CHAR \'({LETRA}|{NUM})\'
BOOL ("True"|"False")
ID {LETRA}({LETRA}|{NUM})*

%%

"\n"		{}

{DELIM} 	{}

"main"		{return TK_MAIN;}

"int"		{return TK_TYPE_INT;}

"float"     {return TK_TYPE_FLOAT;}

"bool"      {return TK_TYPE_BOOL;}

"char"      {return TK_TYPE_CHAR;}

[(){}[\];,]	{ return *yytext; }

[+\-*/%]		{yylval.label = yytext; return *yytext; }

"="		    { return '='; }

{NUM}		{ yylval.label = yytext; return TK_NUM; }
{BOOL}      { yylval.label = yytext; return TK_BOOL; }
{ID}		{ yylval.label = yytext; return TK_ID; }
{REAL}		{ yylval.label = yytext; return TK_REAL; }
{CHAR}      { yylval.label = yytext; return TK_CHAR; }
.			{ *yytext; }

%%
