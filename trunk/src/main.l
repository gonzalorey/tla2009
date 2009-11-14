%{
#include <stdio.h>
#include "match_functions.h"
%}

%x EXTERNLINK

%%
"["?"http://"		BEGIN(EXTERNLINK);
<EXTERNLINK>[\] ]	BEGIN(0);
<EXTERNLINK>[^\] ]*	{matchExtLink(yytext,yyout);};
''[^']*''        	{matchItalic(yytext,yyout);}
'''[^']*'''       {matchBold(yytext,yyout);}
'''''[^']*'''''   {matchBoldItalic(yytext,yyout);}
={2,6}.*={2,6}	{matchHeading(yytext,yyout);}

%%

int
main(int argc, char ** argv)
{
	//mal uso del programa
	if ( argc < 2 || argc > 3) {
		printf("Modo de uso: pwiki archivoDeEntrada [archivoDeSalida]\n");
		return 0;
	}
	
	yyin = fopen(argv[1], "r");
	if (argc == 3)
		yyout = fopen(argv[2], "w");
	else
		yyout = fopen("out.html", "w");
	
	fprintf(yyout, "<html><head></head><body>");
	yylex();
	fprintf(yyout, "</body></html>");
	return 0;
}