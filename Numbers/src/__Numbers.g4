grammar Numbers;

@header {
package parser.src;
}

/*
// Descomente para gerar codigo em c#
options {
    language=CSharp;
}
*/

number: BINARY; // precisa ao menos uma regra de gramática
                 // ignorar isso por hora

NEWLINE : [\r\n ]+;


HEX :  '0' 'x' (NUMBER | ('A'..'F') | ('a'..'f'))+;

BINARY : BIN_DIGIT+ 'b' ; // Sequencia de digitos seguida de b  10100b

DECIMAL : INTEGER'.'(NUMBER+ | NUMBER+(('E' | 'e')?INTEGER+));

INTEGER : ((('-' | '+')?(NUMBER+)) | (NUMBER)+);

BIN_DIGIT : ('0' | '1');

NUMBER : '0'..'9';

ADD_OPER : '+';

SUB_OPER : '-';

MUL_OPER : '*';

DIV_OPER : '/';

POW_OPER : '^';

SHOW_STACK : 'status';

RESET_STACK : 'reset';


