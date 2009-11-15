%{
#include <stdio.h>
#include "match_functions.h"

void printReferences();

#define MAX_LENGTH 150

int elinkNum = 1;

int refNum = 0;
int stateCaller;

char str[MAX_LENGTH];
char str2[MAX_LENGTH];

typedef struct{
	char refName[20];
	char link[MAX_LENGTH];
	char linkName[MAX_LENGTH];
	char explanation[MAX_LENGTH*3];
	int timesRef;	//cantidad de referencias que se hicieron
}refElem;

refElem references[20];
%}

%x ELINK
%x ELINKNAME
%x ILINK
%x ILINKPIPE
%x REDIREC
%x REFCREATE

%%
"http://"[^ ]*$				{matchExtLink(yytext+7, yytext, yyout);}
"[http://"					{stateCaller = 0; BEGIN(ELINK);}
<ELINKNAME>" "*/\]			{sprintf(str2, "[%d]", elinkNum++);BEGIN(ELINK);}
<ELINKNAME>[^\]]+			{strcpy(str2, yytext+1);BEGIN(ELINK);}
<ELINK>[^\] ]*				{strcpy(str, yytext); BEGIN(ELINKNAME);}
<ELINK>\]					{matchExtLink(str, str2, yyout); BEGIN(stateCaller);}
"\n"						{fprintf(yyout, "<br/>");}
''[^']*''        			{matchItalic(yytext,yyout);}
'''[^']*'''       			{matchBold(yytext,yyout);}
'''''[^']*'''''  			{matchBoldItalic(yytext,yyout);}
={2,6}.+={2,6}				{matchHeading(yytext,yyout);}
:{1,3}.+					{matchIndent(yytext,yyout);}

"#REDIRECT [["				BEGIN(REDIREC);
<REDIREC>[^\]]+				{matchRedirect(yytext,yyout);}
<REDIREC>"]]"				BEGIN(0);
			
"[["						{BEGIN(ILINK);}
<ILINK>[^\]\|]+				{strcpy(str,yytext);strcpy(str2,yytext);}
<ILINK>\|[^\]]+				{strcpy(str2,yytext+1);}
<ILINK>"]]"					{matchInterLink(str,str2,yyout);BEGIN(0);}


"<ref name=\""[^"]+\">"[http://"	{
									strncpy(references[refNum].refName, yytext + 11,
										yyleng - 11 - 10);
									BEGIN(REFCREATE);
									}
"<ref name=\""[^"]+\"" />"		{
								yytext[yyleng-4] = '\0';
								int num = getRefByName(yytext + 11);
								if (num != -1) {
									fprintf(yyout, "<sup id=\"cite_ref-%s-%d\"><a href=\"#cite_note-%s\">",
										references[num].refName, references[num].timesRef, 
										references[num].refName);
									references[num].timesRef++;
									fprintf(yyout, "<span>[</span>%d<span>]</span></a></sup>", num+1);
								}
								}
<REFCREATE>[^ ]+				strcpy(references[refNum].link, yytext);
<REFCREATE>" "[^\]]+\]			strncpy(references[refNum].linkName, yytext+1, yyleng - 1 - 1);

<REFCREATE>", "[^<]+"</ref>"	{
								strncpy(references[refNum].explanation, yytext + 2, yyleng - 2 - 6);
								fprintf(yyout, "<sup id=\"cite_ref-%s-%d\"><a href=\"#cite_note-%s\">",
									references[refNum].refName, 0, references[refNum].refName);
								references[refNum].timesRef = 1;
								fprintf(yyout, "<span>[</span>%d<span>]</span></a></sup>", ++refNum);
								BEGIN(0);
								}
								
("<references/>")|("{{Reflist}}")	printReferences();
%%

int
main(int argc, char ** argv)
{
	//si se uso mal el programa
	if ( argc < 2 || argc > 3) {
		printf("Modo de uso: pwiki inputFile [outputFile]\n");
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

void
printReferences() {
	int i, j;
	
	fprintf(yyout, "<ol class=\"references\">");
	for (i = 0; i < refNum; i++) {
		fprintf(yyout, "<li id=\"cite_note-%s\">", references[i].refName);
		if (references[i].timesRef == 1) {
			fprintf(yyout, "<b><a href=\"#cite_ref-%s-%d\">^</a></b>", references[i].refName, 1);
		}
		else {
			fprintf(yyout, "^");
			for (j = 0; j < references[i].timesRef; j++)
				fprintf(yyout, " <sup><b><a href=\"#cite_ref-%s-%d\">%c</a></b></sup>",
					references[i].refName, j, 'a' + j);
		}
		fprintf(yyout, " <a href=\"http://%s\">%s</a>, %s</li>", references[i].link,
			references[i].linkName, references[i].explanation);
	}
	fprintf(yyout, "</ol>");
}

int
getRefByName(char * name) {
	int i;
	for (i = 0; i < refNum; i++) {
		if (strcmp(name, references[i].refName) == 0) {
			return i;
		}
	}
	return -1;
}
