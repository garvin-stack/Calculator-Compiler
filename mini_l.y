%{
 #include <stdio.h>
 #include <stdlib.h>
 #include <map>
 #include <string.h>
 #include <set>

 int tempCount = 0;
 int labelCount = 0;
 extern char* yytext;
 extern int currPos;
 extern FILE *yyin;
 std::map<std::string, std::string> varTemp;
 std::map<std::string, int> arrSize;
 bool mainFunc = false;
 std::set<std::string> funcs;
 std::set<std::string> reserved {"NUMBER", "IDENT", "RETURN", "FUNCTION", "SEMICOLON", "BEGIN_PARAMS", "END_PARAMS", "BEGIN_LOCALS", "END_LOCALS", "BEGIN_BODY", "END_BODY",
 "BEGINLOOP", "ENDLOOP", "COLON", "INTEGER", "COMMA", "ARRAY", "L_SQUARE_BRACKET", "R_SQUARE_BRACKET", "L_PAREN", "R_PAREN", "IF", "ELSE", "THEN" "CONTINUE", "ENDIF", "OF", "READ",
 "WRITE", "DO", "WHILE", "FOR", "TRUE", "FALSE", "ASSIGN", "EQ", "NEQ", "LT", "LTE", "GT", "GTE", "ADD", "SUB", "DIV", "MOD", "OR", "NOT", "Function", "Declarations", "Declaration",
 "Vars", "Var", "Expressions", "Expression", "Idents", "Ident", "ENUM", "Bool-Expr", "Relation-And-Expr", "Relation-Expr-Inv", "Relation-Expr", "Comp", "Multiplicative-Expr", "Term",
 "Statements", "Statement"};

 void yyerror(const char *s);
 int yylex();
 int yyparse();
 std::string new_temp();
 std::string new_label();
%}

%union{
 int num;
 char* ident; 
 struct S {
        char* code;
 } statement;
 struct E {
        char* place;
        char* code;
        bool arr;
 } expression;
}

%start Program
%token <num> NUMBER
%token <ident> IDENT
%type <expression> Function FuncIdent Declarations Declaration Vars Var Expressions Expression Idents Ident 
%type <expression> Bool-Expr Relation-And-Expr Relation-Expr-Inv Relation-Expr Comp Multiplicative-Expr Term
%type <statement> Statements Statement 

%token RETURN FUNCTION SEMICOLON BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY BEGINLOOP ENDLOOP
%token COLON INTEGER COMMA ARRAY L_SQUARE_BRACKET R_SQUARE_BRACKET L_PAREN R_PAREN ENUM
%token IF ELSE THEN CONTINUE ENDIF OF READ WRITE DO WHILE FOR
%token TRUE FALSE
%right ASSIGN
%left OR
%left AND
%right NOT
%left EQ NEQ LT LTE GT GTE
%left ADD SUB
%left MULT DIV MOD

%%

Program:         %empty
        {
                if(!mainFunc){//3
                        printf("Error: No main function declared!\n");
                }
        }
        | Function Program
        {
        }
        ;

Function:       FUNCTION FuncIdent SEMICOLON BEGIN_PARAMS Declarations END_PARAMS BEGIN_LOCALS Declarations END_LOCALS BEGIN_BODY Statements END_BODY//$#
        {
                std::string temp = "func ";//all functions start with func
                temp.append($2.place);//FuncIdent
                temp.append("\n");
                std::string s = $2.place;
                if(s == "main"){//-----------------------------------#3 error
                        mainFunc = true;
                }
                temp.append($5.code);//$5 = Declarations
                std::string decs = $5.code;
                int decNum = 0;
                //Keep track of the number of occurences of . character in the decs
                while(decs.find(".") != std::string::npos) {
                        //continue as long as there's a . chracter founds in the decs
                        int pos = decs.find(".");
                        //the position of the first occurence of the . character
                        decs.replace(pos, 1, "=");//.k -> =k
                        //The . character found at position pos is replaced with the = character.
                        std::string part = ", $" + std::to_string(decNum) + "\n";//=k -> =k $0
                        //This string starts with , $, followed by the current value of decNum
                        decNum++;
                        decs.replace(decs.find("\n", pos), 1, part);
                        //After the = character (which was previously a . character), the code looks for the nexxt
                        //newline chracter \n and replaces it with the part string created in the previous step
                }
                temp.append(decs);
                
                temp.append($8.code);//Declarations
                std::string statements = $11.code;//Statements
                if(statements.find("continue") != std::string::npos) {//------------------------------#9 error
                        printf("ERROR: Continue outside loop in function %s\n", $2.place);
                        //Using continue statement outside loop
                }
                temp.append(statements);
                temp.append("endfunc\n\n");
                printf(temp.c_str());
        }
        ;

Declarations:   Declaration SEMICOLON Declarations
        {
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
        }
        | %empty
        {
                $$.place = strdup("");
                $$.code = strdup("");
        }
        ;

Declaration:    Idents COLON INTEGER // add enum
        {
                int left = 0;
                int right = 0;
                std::string parse($1.place);
                std::string temp;
                bool ex = false;
                while(!ex){
                        right = parse.find("|", left);
                        temp.append(". ");
                        if(right == std::string::npos){ // check if | was found: ----- this is the last iteration when "|" is no longer found
                                std::string ident = parse.substr(left, right);
                                printf("Identifier %s's name is a reserved word1.\n", ident.c_str());
                                if(funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){
                                        printf("Identifier %s is a previosuly declared.\n", ident.c_str());
                                } else {
                                        varTemp[ident] = ident;
                                        arrSize[ident] = 1;
                                }
                                temp.append(ident);
                                ex = true;
                        } else {
                                std::string ident = parse.substr(left, right-left);
                                if(reserved.find(ident) != reserved.end()){//-------------------------------------------------  #5 error
                                        printf("Identifier %s is previously declared2.\n", ident.c_str());
                                } 
                                if(funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){//--------------------#4 error
                                        printf("Identifier %s is previously decalred.\n", ident.c_str());

                                } else {
                                        varTemp[ident] = ident;
                                        arrSize[ident] = 1;
                                }
                                temp.append(ident);
                                left = right+1;
                        }
                        temp.append("\n");
                }
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
        }
        | Idents COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER
        {
                 size_t left = 0;
                 size_t right = 0;
                 std::string parse($1.place);
                 std::string temp;
                 bool ex = false;
                 while(!ex) {
                        right = parse.find("|", left);
                        temp.append(".[] ");
                        if(right == std::string::npos){
                                std::string ident = parse.substr(left, right);
                                if(reserved.find(ident) != reserved.end()){
                                        printf("Identifier %s's name is a reserved word3.\n", ident.c_str());
                                }
                                if(funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){
                                        printf("Identifier %s is previously declared.\n", ident.c_str());
                                } else {
                                        if($5 <= 0){
                                                printf("Declaring array ident %s of size <= 0.\n", ident.c_str());
                                        }
                                        varTemp[ident] = ident;
                                        arrSize[ident] = $5;
                                }
                                temp.append(ident);
                                ex = true;
                        } else {
                                std::string ident = parse.substr(left, right-left);
                                if(reserved.find(ident) != reserved.end()){
                                        printf("Identifier %s's name is a reserved word4.\n", ident.c_str());
                                }
                                if(funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){
                                        printf("Identifier %s's is previously decalred.\n", ident.c_str());
                                } else {
                                        if($5 <= 0){
                                                printf("Declaring array ident %s of size <= 0.\n", ident.c_str());
                                        }
                                        varTemp[ident] = ident;
                                        arrSize[ident] = $5;
                                }
                                temp.append(ident);
                                left = right+1;
                        }
                        temp.append(", ");
                        temp.append(std::to_string($5));
                        temp.append("\n");
                 }
                 $$.code = strdup(temp.c_str());
                 $$.place = strdup("");
        }
        | Idents COLON ENUM L_PAREN Idents R_PAREN
        {
                int left = 0;
                int right = 0;
                std::string parse($1.place);
                std::string temp;
                bool ex = false;
                while(!ex){
                        right = parse.find("|", left);
                        temp.append(". ");
                        if(right == std::string::npos){ // check if | was found: ----- this is the last iteration when "|" is no longer found
                                std::string ident = parse.substr(left, right);
                                printf("Identifier %s's name is a reserved word5.\n", ident.c_str());
                                if(funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){
                                
                                        printf("Identifier %s is a previosuly declared.\n", ident.c_str());
                                } else {
                                        varTemp[ident] = ident;
                                        arrSize[ident] = 1;
                                }
                                temp.append(ident);
                                ex = true;
                        } else {
                                std::string ident = parse.substr(left, right-left);
                                if(reserved.find(ident) != reserved.end()){//-------------------------------------------------  #5 error
                                        printf("Identifier %s is previously declared.\n", ident.c_str());
                                } 
                                if(funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){//--------------------#4 error
                                        printf("Identifier %s is previously declared.\n", ident.c_str());

                                } else {
                                        varTemp[ident] = ident;
                                        arrSize[ident] = 1;
                                }
                                temp.append(ident);
                                left = right+1;
                        }
                        temp.append("\n");
                }
                int left1 = 0;
                int right1 = 0;
                std::string parse1($5.place);
                ex = false;
                while(!ex){
                        right1 = parse1.find("|", left1);
                        temp.append(". ");
                        if(right1 == std::string::npos){ // check if | was found: ----- this is the last iteration when "|" is no longer found
                                std::string ident1 = parse1.substr(left1, right1);
                                printf("Identifier %s's name is a reserved word5.\n", ident1.c_str());
                                if(funcs.find(ident1) != funcs.end() || varTemp.find(ident1) != varTemp.end()){
                                
                                        printf("Identifier %s is a previosuly declared.\n", ident1.c_str());
                                } else {
                                        varTemp[ident1] = ident1;
                                        arrSize[ident1] = 1;
                                }
                                temp.append(ident1);
                                ex = true;
                        } else {
                                std::string ident1 = parse.substr(left1, right1-left1);
                                if(reserved.find(ident1) != reserved.end()){//-------------------------------------------------  #5 error
                                        printf("Identifier %s is previously declared.\n", ident1.c_str());
                                } 
                                if(funcs.find(ident1) != funcs.end() || varTemp.find(ident1) != varTemp.end()){//--------------------#4 error
                                        printf("Identifier %s is previously declared.\n", ident1.c_str());

                                } else {
                                        varTemp[ident1] = ident1;
                                        arrSize[ident1] = 1;
                                }
                                temp.append(ident1);
                                left = right+1;
                        }
                        temp.append("\n");
                }                
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
        }
        ;

FuncIdent:      IDENT
        {
                if(funcs.find($1) != funcs.end()){
                        printf("function name %s already declared.\n", $1);
                } else {
                        funcs.insert($1);
                }
                $$.place = strdup($1);
                $$.code = strdup("");
        }
        ;

Idents:         Ident
        {
                $$.place = strdup($1.place);
                $$.code = strdup("");
        }
        | Ident COMMA Idents
        {
                std::string temp;
                temp.append($1.place);
                temp.append("|");
                temp.append($3.place); //temp = a | b
                $$.place = strdup(temp.c_str());
                $$.code = strdup("");
        }
        ;

Ident: IDENT
        {
                $$.place = strdup($1);
                $$.code = strdup("");
        }
        ;
Statements: Statement SEMICOLON Statements
        {
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
        }
        | Statement SEMICOLON
        {
                $$.code = strdup($1.code);
        }
        ;

Statement: Var ASSIGN Expression
        {
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                std::string middle = $3.place;
                if($1.arr && $3.arr){//array or not array
                        temp += "[]=";//index = index
                } else if($1.arr){
                        temp += "[]=";// index = value
                } else if($3.arr){
                        temp += "= "; // value = index
                } else {
                        temp += "= "; // value = value
                }
                temp.append($1.place);
                temp.append(", ");
                temp.append(middle);
                temp += "\n";
                $$.code = strdup(temp.c_str());
        }
        | IF Bool-Expr THEN Statements ENDIF
        {
                std::string ifS = new_label();//L0
                std::string after = new_label();//L1
                std::string temp;
                temp.append($2.code);
                temp = temp + "?:= " + ifS + ", " + $2.place + "\n";//If true, jump to :ifS 
                temp = temp + ":= " + after + "\n";// reached if above not true, skips $4 code
                temp = temp + ": " + ifS + "\n";
                temp.append($4.code);
                temp = temp + ": " + after + "\n";
                $$.code = strdup(temp.c_str());
        }
        | IF Bool-Expr THEN Statements ELSE Statements ENDIF
        {
                std::string ifS = new_label();//L0
                std::string after = new_label();//L1
                std::string temp;
                temp.append($2.code);
                temp = temp + "?:= " + ifS + ", " + $2.place + "\n";//If true, jump to :ifS 
                temp.append($6.code); // reached if above not true, does $6 code
                temp = temp + ":= " + after + "\n";// Prevents else code from running its code
                temp = temp + ": " + ifS + "\n";
                temp.append($4.code);//Reach by :ifS jump, if's code
                temp = temp + ": " + after + "\n";
                $$.code = strdup(temp.c_str()); 
        }
        | WHILE Bool-Expr BEGINLOOP Statements ENDLOOP
        {
                std::string temp;
                std::string begin = new_label();
                std::string inner = new_label();
                std::string after = new_label();
                std::string code = $4.code;
                size_t pos = code.find("continue");
                while(pos != std::string::npos) {
                        code.replace(pos, 8, ":= " + begin);
                        pos = code.find("continue");
                }
                temp.append(": ");
                temp += begin + "\n";
                temp.append($2.code);
                temp += "?:= " + inner + ", ";
                temp += ": " + inner + "\n";
                temp.append(code);
                temp += ":= " + begin + "\n";      
                temp += ": " + after + "\n";
                $$.code = strdup(temp.c_str());
        }
        | DO BEGINLOOP Statements ENDLOOP WHILE Bool-Expr
        {
                std::string temp;
                std::string begin = new_label();
                std::string condition = new_label();
                std::string code = $3.code;
                size_t pos = code.find("continue");
                while(pos != std::string::npos){
                        code.replace(pos, 8, ":= " + condition);
                        pos = code.find("continue");
                }
                temp.append(": ");
                temp += begin + "\n";
                temp.append(code);
                temp += ": " + condition + "\n";
                temp.append($6.code);
                temp += "?:= " + begin + ", ";
                temp.append($6.place);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
        }
        | READ Vars
        {
                std::string temp;
                temp.append($2.code);
                size_t pos = temp.find("|", 0);
                while(pos != std::string::npos){
                        temp.replace(pos, 1, "<");
                        pos = temp.find("|", pos);
                }
                $$.code = strdup(temp.c_str());
        }
        | WRITE Vars
        {
                std::string temp;
                temp.append($2.code);
                size_t pos = temp.find("|", 0);
                while(pos != std::string::npos){
                        temp.replace(pos, 1, ">");
                        pos = temp.find("|", pos);
                }
                $$.code = strdup(temp.c_str());
        }
        | CONTINUE
        {
                $$.code = strdup("continue\n");
        }
        | RETURN Expression{
                std::string temp;
                temp.append($2.code);
                temp.append("ret ");
                temp.append($2.place);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
        }
        ;

Bool-Expr: Relation-And-Expr OR Bool-Expr
        {
                std::string temp;
                std::string dst = new_temp();
                temp.append($1.code);
                temp += ". " + dst + "\n";
                temp += "|| " + dst + ", ";
                temp.append($3.code);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | Relation-And-Expr
        {
                $$.code = strdup($1.code);
                $$.place = strdup($1.place);                
        }
        ;

Relation-And-Expr: Relation-Expr AND Relation-And-Expr
        {
                std::string temp;
                std::string dst = new_temp();
                temp.append($1.code);
                temp += ". " + dst + "\n";
                temp += "&& " + dst + ", ";
                temp.append($3.code);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | Relation-Expr-Inv
        {
                $$.code = strdup($1.code);
                $$.place = strdup($1.place);
        }
        ;

Relation-Expr-Inv: NOT Relation-Expr-Inv
        {
                std::string temp;
                std::string dst = new_temp();
                temp.append($2.code);
                temp += ". " + dst + "\n";
                temp += "! " + dst + ", ";
                temp.append($2.place);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | Relation-Expr
        {
                $$.code = strdup($1.code);
                $$.place = strdup($1.place);
        }
        ;

Relation-Expr: Expression Comp Expression
        {
                std::string dst = new_temp();
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                temp = temp + ". " + dst + "\n" + $2.place + dst + ", " + $1.place + ", " + $3.place + "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | TRUE
        {
                $$.place = strdup("1"); 
        }
        | FALSE
        {
                $$.place = strdup("0");
        }
        | L_PAREN Bool-Expr R_PAREN
        {
                $$.code = strdup($2.code);
                $$.place = strdup($2.place);
        }
        ;

Comp: EQ
        {
                $$.place = strdup("==");
        }
        | NEQ
        {
                $$.place = strdup("<>");
        }
        | LT
        {
                $$.place = strdup("<");
        }
        | LTE
        {
                $$.place = strdup("<=");
        }
        | GT
        {
                $$.place = strdup(">");
        }
        | GTE
        {
                $$.place = strdup(">=");
        }
        ;

Expression: Multiplicative-Expr ADD Expression
        {
                std::string dst = new_temp();
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                temp = temp + ". " + dst + "\n" + "+ " + dst + ", " + $1.place + ", " + $3.place + "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());

        }
        | Multiplicative-Expr SUB Expression
        {
                std::string dst = new_temp();
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                temp = temp + ". " + dst + "\n" + "- " + dst + ", " + $1.place + ", " + $3.place + "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | Multiplicative-Expr
        {
                $$.code = strdup($1.code);
                $$.place = strdup($1.place);
        }
        ;

//not sure
Expressions: Expression COMMA Expressions
        {
                std::string temp;
                temp.append($1.code);
                temp.append("param ");
                temp.append($1.place);
                temp.append("\n");
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
        }
        | Expression
        {
                std::string temp;
                temp.append($1.code);
                temp.append("param ");
                temp.append($1.place);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
        }
        ;

Multiplicative-Expr: Term
        {
                $$.code = strdup($1.code);
                $$.place = strdup($1.place);
        }
        | Term MULT Multiplicative-Expr
        {
                std::string dst = new_temp();
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                temp = temp + ". " + dst + "\n" + "* " + dst + ", " + $1.place + ", " + $3.place + "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());                
        }
        | Term DIV Multiplicative-Expr
        {
                std::string dst = new_temp();
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                temp = temp + ". " + dst + "\n" + "/ " + dst + ", " + $1.place + ", " + $3.place + "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | Term MOD Multiplicative-Expr
        {
                std::string dst = new_temp();
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                temp = temp + ". " + dst + "\n" + "% " + dst + ", " + $1.place + ", " + $3.place + "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        ;

Term: SUB Var
        {
                std::string temp;
                std::string dst = new_temp();
                temp.append($2.code);
                temp.append(". ");
                temp.append(dst);
                temp.append("\n");
                if($2.arr){
                        temp.append("=[] ");
                        temp.append(dst);
                        temp.append(", ");
                        temp.append($2.place);
                        temp.append("\n");
                } else {
                        temp.append("= ");
                        temp.append(dst);
                        temp.append(", ");
                        temp.append($2.place);
                        temp.append("\n");
                }
                temp.append($2.place);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
                $$.arr = false;
        }
        | SUB NUMBER
        {
                std::string temp;
                temp.append("-");
                temp.append(std::to_string($2));
                $$.place = strdup(temp.c_str());
                $$.code = strdup("");
        }
        | SUB L_PAREN Expression R_PAREN
        {
                std::string dst = new_temp();
                std::string temp;
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | Var
        {       
                std::string temp;
                std::string dst = new_temp();
                if($1.arr){
                        temp.append($1.code);
                        temp += ". " + dst + "\n" + "=[] " + dst + ", ";
                        temp.append("$1.place");
                        temp.append("\n");
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
                        $$.arr = false;              
                } else {
                        $$.code = strdup($1.code);
                        $$.place = strdup($1.place);
                }
        }
        | NUMBER
        {
                std::string temp;
                temp.append(std::to_string($1));
                $$.place = strdup(temp.c_str());
                $$.code = strdup("");
        }
        | L_PAREN Expression R_PAREN
        {
                $$.code = strdup($2.code);
                $$.place = strdup($2.place);
        }
        ;
Vars: Var COMMA Vars
        {
                std::string temp;
                temp.append($1.code);
                if($1.arr){
                        temp.append(".[]| ");
                } else {
                        temp.append(".| ");
                }
                temp.append($1.place);
                temp.append("\n");
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
        }
        | Var
        { 
                std::string temp;
                temp.append($1.code);
                if($1.arr){
                        temp.append(".[]| ");
                } else {
                        temp.append(".| ");
                }
                temp.append($1.place);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
        }
        ;

Var: Ident 
        {
                std::string temp;
                std::string ident = $1.place;
                if(funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end()){
                        printf("Identifier %s is not declared.\n", ident.c_str());
                } else if(arrSize[ident] > 1){
                        printf("Did not provide index for array Identifier %s.\n", ident.c_str());
                }
                $$.code = strdup("");
                $$.place = strdup(ident.c_str());
                $$.arr = false;
        }
        | Ident L_SQUARE_BRACKET Expression R_SQUARE_BRACKET
        {
                std::string temp;
                std::string ident = $1.place;
                if(funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end()){
                        printf("Identifier %s is not declared.\n", ident.c_str());
                } else if(arrSize[ident] == 1){
                        printf("Did not provide index for array Identifier %s.\n", ident.c_str());
                }
                temp.append($1.place);
                temp.append(", ");
                temp.append($3.place);
                $$.code = strdup($3.code);
                $$.place = strdup(ident.c_str());
                $$.arr = true;
        }
        ;
%%

int main(int argc, char **argv) {
   if (argc > 1) {
      yyin = fopen(argv[1], "r");
      if (yyin == NULL){ 
         printf("syntax: %s filename\n", argv[0]);
      }
   }
   yyparse(); // Calls yylex() for tokens.
   return 0;
}

void yyerror(const char *msg) {
        extern int yylineno;
        extern char *yytext;
        printf("** Line %d, position %d: %s\n", yylineno, currPos, yytext);
        exit(1);
}

std::string new_temp(){
        std::string t = "t" + std::to_string(tempCount);
        tempCount++;
        return t;
}

std::string new_label(){
        std::string l = "L" + std::to_string(labelCount);
        labelCount++;
        return l;
}
