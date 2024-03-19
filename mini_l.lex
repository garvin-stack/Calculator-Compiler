%{   
   #include <string>
   #include "y.tab.h"
   int currLine = 1, currPos = 0;

%}

DIGIT    [0-9]
COMMENT  ##.*
VAR      [a-zA-Z][a-zA-Z_0-9]*
BADVARNUM      [_0-9]+[a-zA-Z_]+[a-zA-Z_0-9]*
BADVARUNDER    [a-zA-Z_]+[a-zA-Z_0-9]*_+



%%

{COMMENT}      {currLine++; currPos = 0;}

"return"       {return RETURN; currPos += yyleng;}
"function"     {return FUNCTION; currPos += yyleng;}
";"            {return SEMICOLON; currPos += yyleng;}
"beginparams"  {return BEGIN_PARAMS; currPos += yyleng;}
"endparams"    {return END_PARAMS; currPos += yyleng;}
"beginlocals"  {return BEGIN_LOCALS; currPos += yyleng;}
"endlocals"    {return END_LOCALS; currPos += yyleng;}
"beginbody"    {return BEGIN_BODY; currPos += yyleng;}
"endbody"      {return END_BODY; currPos += yyleng;}
"beginloop"    {return BEGINLOOP; currPos += yyleng;}
"endloop"      {return ENDLOOP; currPos += yyleng;}
":="           {return ASSIGN; currPos += yyleng;}
"=="           {return EQ; currPos += yyleng;}
"<>"           {return NEQ; currPos += yyleng;}
"<"            {return LT; currPos += yyleng;}
"<="           {return LTE; currPos += yyleng;}
">"            {return GT; currPos += yyleng;}
">="           {return GTE; currPos += yyleng;}
":"            {return COLON; currPos += yyleng;}
"+"            {return ADD; currPos += yyleng;}
"-"            {return SUB; currPos += yyleng;}
"*"            {return MULT; currPos += yyleng;}
"/"            {return DIV; currPos += yyleng;}
"%"            {return MOD; currPos += yyleng;}
"integer"      {return INTEGER; currPos += yyleng;}
","            {return COMMA; currPos += yyleng;}
"array"        {return ARRAY; currPos += yyleng;}
"["            {return L_SQUARE_BRACKET; currPos += yyleng;}
"]"            {return R_SQUARE_BRACKET; currPos += yyleng;}
"("            {return L_PAREN; currPos += yyleng;}
")"            {return R_PAREN; currPos += yyleng;}
"if"           {return IF; currPos += yyleng;}
"else"         {return ELSE; currPos += yyleng;}
"then"         {return THEN; currPos += yyleng;}
"continue"     {return CONTINUE; currPos += yyleng;}
"endif"        {return ENDIF; currPos += yyleng;}
"of"           {return OF; currPos += yyleng;}
"read"         {return READ; currPos += yyleng;}
"write"        {return WRITE; currPos += yyleng;}
"do"           {return DO; currPos += yyleng;}
"while"        {return WHILE; currPos += yyleng;}
"and"          {return AND; currPos += yyleng;}
"for"          {return FOR; currPos += yyleng;}
"or"           {return OR; currPos += yyleng;}
"not"          {return NOT; currPos += yyleng;}
"true"         {return TRUE; currPos += yyleng;}
"false"        {return FALSE; currPos += yyleng;}
"enum"         {return ENUM; currPos += yyleng;}
{BADVARUNDER}     {printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n",
                currLine, currPos, yytext); exit(0);}
{BADVARNUM}  {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n",
                currLine, currPos, yytext); exit(0);}
{VAR}+         {yylval.ident = strdup(yytext); currPos += yyleng; return IDENT;}
{DIGIT}        {yylval.num = atoi(yytext); currPos += yyleng; return NUMBER;}

[ \t]+         {/* ignore spaces */ currPos += yyleng;}

"\n"           {currLine++; currPos = 1;}

.              {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos, yytext); exit(0);}

%%
