%{
    #include <string>
    %}

ESPACE [ \t]
DIGIT [0-9]
LETTER [A-Za-z_]

DELIM {ESPACE}+
NUM {DIGIT}+
ID {LETTER}({LETTER}|{NUM})*
CHAR \'({LETTER}|{NUM})\'
REAL {NUM}+("."{NUM}+)?


%%

"\n"        {}

{DELIM}     {}

"main"      {return TK_MAIN;}

"int"		{return TK_TIPO_INT;}

[(){}[\];,]	{ return *yytext; }

[+\-*/]		{ return *yytext; }

"="		    { return '='; }

{NUM}		{ yylval.label = yytext; return TK_NUM; }
{ID}		{ yylval.label = yytext; return TK_ID; }

.			{ *yytext; }

%%
