package parser.src;

import org.antlr.v4.runtime.*;// class ANTLRInputStream , Token
import java.io.*;
import java.util.*;

import javax.swing.JFileChooser;
import javax.swing.filechooser.*;

public class ExemploSymbolTable {

	public static void main(String[] args) throws Exception {
		
		Stack<Object> pilhaValores = new Stack<>();
		int op2 = Integer.parseInt(pilhaValores.pop().toString());
		
		/*
		NestedSymbolTable<Integer> mt = new NestedSymbolTable<Integer>();
        mt.store("lala", 0);
        mt.store("lele", 1);
        
        NestedSymbolTable<Integer> nt1 = new NestedSymbolTable<Integer>(mt);
        nt1.store("lala", 10);
        
        NestedSymbolTable<Integer> nt2 = new NestedSymbolTable<Integer>(mt);
        nt2.store("lala", 11);

        System.out.println(nt2.lookup("lele"));
        for (SymbolEntry<Integer> entry : nt2.getEntries()) {
            System.out.println("nt2 Entry: " + entry);
        }

        for (SymbolEntry<Integer> entry : nt1.getEntries()) {
            System.out.println("nt1 Entry: " + entry);
        }

        for (SymbolEntry<Integer> entry : mt.getEntries()) {
            System.out.println("mt Entry: " + entry);
        }
        */
	}
	
}
