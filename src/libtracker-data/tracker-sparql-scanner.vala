/*
 * Copyright (C) 2009, Nokia
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA.
 */

public class Tracker.SparqlScanner : Object {
	char* current;
	char* end;

	int line;
	int column;

	public SparqlScanner (char* input, long len) {
		char* begin = input;
		end = begin + len;

		current = begin;

		line = 1;
		column = 1;
	}

	public void seek (SourceLocation location) {
		current = location.pos;
		line = location.line;
		column = location.column;
	}

	SparqlTokenType get_identifier_or_keyword (char* begin, int len) {
		switch (len) {
		case 1:
			switch (begin[0]) {
			case 'A':
			case 'a':
				return SparqlTokenType.A;
			}
			break;
		case 2:
			switch (begin[0]) {
			case 'A':
			case 'a':
				if (matches (begin, "AS")) return SparqlTokenType.AS;
				break;
			case 'B':
			case 'b':
				if (matches (begin, "BY")) return SparqlTokenType.BY;
				break;
			}
			break;
		case 3:
			switch (begin[0]) {
			case 'A':
			case 'a':
				switch (begin[1]) {
				case 'S':
				case 's':
					switch (begin[2]) {
					case 'C':
					case 'c':
						if (matches (begin, "ASC")) return SparqlTokenType.ASC;
						break;
					case 'K':
					case 'k':
						if (matches (begin, "ASK")) return SparqlTokenType.ASK;
						break;
					}
					break;
				case 'V':
				case 'v':
					if (matches (begin, "AVG")) return SparqlTokenType.AVG;
					break;
				}
				break;
			case 'M':
			case 'm':
				switch (begin[1]) {
				case 'A':
				case 'a':
					if (matches (begin, "MAX")) return SparqlTokenType.MAX;
					break;
				case 'I':
				case 'i':
					if (matches (begin, "MIN")) return SparqlTokenType.MIN;
					break;
				}
				break;
			case 'S':
			case 's':
				switch (begin[1]) {
				case 'T':
				case 't':
					if (matches (begin, "STR")) return SparqlTokenType.STR;
					break;
				case 'U':
				case 'u':
					if (matches (begin, "SUM")) return SparqlTokenType.SUM;
					break;
				}
				break;
			}
			break;
		case 4:
			switch (begin[0]) {
			case 'B':
			case 'b':
				if (matches (begin, "BASE")) return SparqlTokenType.BASE;
				break;
			case 'D':
			case 'd':
				switch (begin[1]) {
				case 'E':
				case 'e':
					if (matches (begin, "DESC")) return SparqlTokenType.DESC;
					break;
				case 'R':
				case 'r':
					if (matches (begin, "DROP")) return SparqlTokenType.DROP;
					break;
				}
				break;
			case 'F':
			case 'f':
				if (matches (begin, "FROM")) return SparqlTokenType.FROM;
				break;
			case 'I':
			case 'i':
				if (matches (begin, "INTO")) return SparqlTokenType.INTO;
				break;
			case 'L':
			case 'l':
				if (matches (begin, "LANG")) return SparqlTokenType.LANG;
				break;
			case 'T':
			case 't':
				if (matches (begin, "TRUE")) return SparqlTokenType.TRUE;
				break;
			}
			break;
		case 5:
			switch (begin[0]) {
			case 'B':
			case 'b':
				if (matches (begin, "BOUND")) return SparqlTokenType.BOUND;
				break;
			case 'C':
			case 'c':
				if (matches (begin, "COUNT")) return SparqlTokenType.COUNT;
				break;
			case 'G':
			case 'g':
				switch (begin[2]) {
				case 'A':
				case 'a':
					if (matches (begin, "GRAPH")) return SparqlTokenType.GRAPH;
					break;
				case 'O':
				case 'o':
					if (matches (begin, "GROUP")) return SparqlTokenType.GROUP;
					break;
				}
				break;
			case 'L':
			case 'l':
				if (matches (begin, "LIMIT")) return SparqlTokenType.LIMIT;
				break;
			case 'N':
			case 'n':
				if (matches (begin, "NAMED")) return SparqlTokenType.NAMED;
				break;
			case 'O':
			case 'o':
				if (matches (begin, "ORDER")) return SparqlTokenType.ORDER;
				break;
			case 'R':
			case 'r':
				if (matches (begin, "REGEX")) return SparqlTokenType.REGEX;
				break;
			case 'U':
			case 'u':
				if (matches (begin, "UNION")) return SparqlTokenType.UNION;
				break;
			case 'W':
			case 'w':
				if (matches (begin, "WHERE")) return SparqlTokenType.WHERE;
				break;
			case 'F':
			case 'f':
				if (matches (begin, "FALSE")) return SparqlTokenType.FALSE;
				break;
			case 'I':
			case 'i':
				switch (begin[1]) {
				case 'S':
				case 's':
					switch (begin[2]) {
					case 'I':
					case 'i':
						if (matches (begin, "ISIRI")) return SparqlTokenType.ISIRI;
						break;
					case 'U':
					case 'u':
						if (matches (begin, "ISURI")) return SparqlTokenType.ISURI;
						break;
					}
					break;
				}
				break;
			}
			break;
		case 6:
			switch (begin[0]) {
			case 'D':
			case 'd':
				if (matches (begin, "DELETE")) return SparqlTokenType.DELETE;
				break;
			case 'F':
			case 'f':
				if (matches (begin, "FILTER")) return SparqlTokenType.FILTER;
				break;
			case 'I':
			case 'i':
				if (matches (begin, "INSERT")) return SparqlTokenType.INSERT;
				break;
			case 'O':
			case 'o':
				if (matches (begin, "OFFSET")) return SparqlTokenType.OFFSET;
				break;
			case 'P':
			case 'p':
				if (matches (begin, "PREFIX")) return SparqlTokenType.PREFIX;
				break;
			case 'S':
			case 's':
				if (matches (begin, "SELECT")) return SparqlTokenType.SELECT;
				break;
			}
			break;
		case 7:
			switch (begin[0]) {
			case 'R':
			case 'r':
				if (matches (begin, "REDUCED")) return SparqlTokenType.REDUCED;
				break;
			case 'I':
			case 'i':
				if (matches (begin, "ISBLANK")) return SparqlTokenType.ISBLANK;
				break;
			}
			break;
		case 8:
			switch (begin[0]) {
			case 'D':
			case 'd':
				switch (begin[1]) {
				case 'A':
				case 'a':
					if (matches (begin, "DATATYPE")) return SparqlTokenType.DATATYPE;
					break;
				case 'E':
				case 'e':
					if (matches (begin, "DESCRIBE")) return SparqlTokenType.DESCRIBE;
					break;
				case 'I':
				case 'i':
					if (matches (begin, "DISTINCT")) return SparqlTokenType.DISTINCT;
					break;
				}
				break;
			case 'O':
			case 'o':
				if (matches (begin, "OPTIONAL")) return SparqlTokenType.OPTIONAL;
				break;
			case 'S':
			case 's':
				if (matches (begin, "SAMETERM")) return SparqlTokenType.SAMETERM;
				break;
			}
			break;
		case 9:
			switch (begin[0]) {
			case 'C':
			case 'c':
				if (matches (begin, "CONSTRUCT")) return SparqlTokenType.CONSTRUCT;
				break;
			case 'I':
			case 'i':
				if (matches (begin, "ISLITERAL")) return SparqlTokenType.ISLITERAL;
				break;
			}
			break;
		case 11:
			if (matches (begin, "LANGMATCHES")) return SparqlTokenType.LANGMATCHES;
			break;
		case 12:
			if (matches (begin, "GROUP_CONCAT")) return SparqlTokenType.GROUP_CONCAT;
			break;
		}
		return SparqlTokenType.PN_PREFIX;
	}

	SparqlTokenType read_number () {
		var type = SparqlTokenType.INTEGER;

		// integer part
		if (current < end - 2 && current[0] == '0'
		    && current[1] == 'x' && current[2].isxdigit ()) {
			// hexadecimal integer literal
			current += 2;
			while (current < end && current[0].isxdigit ()) {
				current++;
			}
		} else {
			// decimal number
			while (current < end && current[0].isdigit ()) {
				current++;
			}
		}

		// fractional part
		if (current < end - 1 && current[0] == '.' && current[1].isdigit ()) {
			type = SparqlTokenType.DOUBLE;
			current++;
			while (current < end && current[0].isdigit ()) {
				current++;
			}
		}

		// exponent part
		if (current < end && current[0].tolower () == 'e') {
			type = SparqlTokenType.DOUBLE;
			current++;
			if (current < end && (current[0] == '+' || current[0] == '-')) {
				current++;
			}
			while (current < end && current[0].isdigit ()) {
				current++;
			}
		}

		// type suffix
		if (current < end) {
			switch (current[0]) {
			case 'l':
			case 'L':
				if (type == SparqlTokenType.INTEGER) {
					current++;
					if (current < end && current[0].tolower () == 'l') {
						current++;
					}
				}
				break;
			case 'u':
			case 'U':
				if (type == SparqlTokenType.INTEGER) {
					current++;
					if (current < end && current[0].tolower () == 'l') {
						current++;
						if (current < end && current[0].tolower () == 'l') {
							current++;
						}
					}
				}
				break;
			case 'f':
			case 'F':
			case 'd':
			case 'D':
				type = SparqlTokenType.DOUBLE;
				current++;
				break;
			}
		}

		return type;
	}

	bool is_pn_char (char c) {
		return (c.isalnum () || c == '_' || c == '-');
	}

	bool is_pn_local_char (char c) {
		return (c.isalnum () || c == '_' || c == '-' || c == '.');
	}

	bool is_varname_char (char c) {
		return (c.isalnum () || c == '_');
	}

	public SparqlTokenType read_token (out SourceLocation token_begin, out SourceLocation token_end) throws SparqlError {
		space ();

		SparqlTokenType type;
		char* begin = current;
		token_begin.pos = begin;
		token_begin.line = line;
		token_begin.column = column;

		int token_length_in_chars = -1;

		if (current >= end) {
			type = SparqlTokenType.EOF;
		} else if (current[0].isalpha ()) {
			// keyword or prefixed name
			int len = 0;
			while (current < end && is_pn_char (current[0])) {
				current++;
				len++;
			}
			type = get_identifier_or_keyword (begin, len);
		} else if (current[0].isdigit ()) {
			type = read_number ();
		} else {
			switch (current[0]) {
			case '{':
				type = SparqlTokenType.OPEN_BRACE;
				current++;
				break;
			case '}':
				type = SparqlTokenType.CLOSE_BRACE;
				current++;
				break;
			case '(':
				type = SparqlTokenType.OPEN_PARENS;
				current++;
				break;
			case ')':
				type = SparqlTokenType.CLOSE_PARENS;
				current++;
				break;
			case '[':
				type = SparqlTokenType.OPEN_BRACKET;
				current++;
				break;
			case ']':
				type = SparqlTokenType.CLOSE_BRACKET;
				current++;
				break;
			case '.':
				type = SparqlTokenType.DOT;
				current++;
				break;
			case ':':
				type = SparqlTokenType.COLON;
				current++;
				while (current < end && is_pn_local_char (current[0])) {
					current++;
				}
				if (current[-1] == '.') {
					// last character must not be a dot (conflict with SparqlTokenType.DOT)
					current--;
				}
				break;
			case ',':
				type = SparqlTokenType.COMMA;
				current++;
				break;
			case ';':
				type = SparqlTokenType.SEMICOLON;
				current++;
				break;
			case '?':
			case '$':
				type = SparqlTokenType.NONE;
				current++;
				while (current < end && is_varname_char (current[0])) {
					type = SparqlTokenType.VAR;
					current++;
				}
				break;
			case '@':
				type = SparqlTokenType.NONE;
				current++;
				if (current < end - "prefix".len () && matches (current, "PREFIX")) {
					type = SparqlTokenType.ATPREFIX;
					current += "prefix".len ();
				} else if (current < end - "base".len () && matches (current, "BASE")) {
					type = SparqlTokenType.ATBASE;
					current += "base".len ();
				}
				break;
			case '|':
				type = SparqlTokenType.NONE;
				current++;
				if (current < end) {
					switch (current[0]) {
					case '|':
						type = SparqlTokenType.OP_OR;
						current++;
						break;
					}
				}
				break;
			case '&':
				type = SparqlTokenType.NONE;
				current++;
				if (current < end) {
					switch (current[0]) {
					case '&':
						type = SparqlTokenType.OP_AND;
						current++;
						break;
					}
				}
				break;
			case '=':
				type = SparqlTokenType.OP_EQ;
				current++;
				break;
			case '<':
				type = SparqlTokenType.OP_LT;
				current++;
				if (current < end) {
					// check whether token is an IRI
					while (current < end && current[0] > ' ') {
						switch (current[0]) {
						case '<':
						case '>':
						case '"':
						case '{':
						case '}':
						case '|':
						case '^':
						case '`':
						case '\\':
							// not an IRI
							break;
						default:
							current++;
							continue;
						}
						break;
					}
					if (current < end && current[0] == '>') {
						type = SparqlTokenType.IRI_REF;
						current++;
						break;
					} else {
						current = begin + 1;
					}
					switch (current[0]) {
					case '=':
						type = SparqlTokenType.OP_LE;
						current++;
						break;
					}
				}
				break;
			case '>':
				type = SparqlTokenType.OP_GT;
				current++;
				if (current < end && current[0] == '=') {
					type = SparqlTokenType.OP_GE;
					current++;
				}
				break;
			case '!':
				type = SparqlTokenType.OP_NEG;
				current++;
				if (current < end && current[0] == '=') {
					type = SparqlTokenType.OP_NE;
					current++;
				}
				break;
			case '+':
				type = SparqlTokenType.PLUS;
				current++;
				break;
			case '-':
				type = SparqlTokenType.MINUS;
				current++;
				break;
			case '*':
				type = SparqlTokenType.STAR;
				current++;
				break;
			case '/':
				type = SparqlTokenType.DIV;
				current++;
				break;
			case '\'':
			case '"':
				if (current < end - 6 && begin[1] == begin[0] && begin[2] == begin[0]) {
					if (begin[0] == '\'') {
						type = SparqlTokenType.STRING_LITERAL_LONG1;
					} else {
						type = SparqlTokenType.STRING_LITERAL_LONG2;
					}

					token_length_in_chars = 6;
					current += 3;
					while (current < end - 4) {
						if (current[0] == begin[0] && current[1] == begin[0] && current[2] == begin[0]) {
							break;
						} else if (current[0] == '\n') {
							current++;
							line++;
							column = 1;
							token_length_in_chars = 3;
						} else {
							unichar u = ((string) current).get_char_validated ((long) (end - current));
							if (u != (unichar) (-1)) {
								current += u.to_utf8 (null);
								token_length_in_chars++;
							} else {
								throw new SparqlError.PARSE ("%d.%d: invalid UTF-8 character", line, column + token_length_in_chars);
							}
						}
					}
					if (current[0] == begin[0] && current[1] == begin[0] && current[2] == begin[0]) {
						current += 3;
					} else {
						throw new SparqlError.PARSE ("%d.%d: syntax error, expected \"\"\"", line, column + token_length_in_chars);
					}
					break;
				}

				if (begin[0] == '\'') {
					type = SparqlTokenType.STRING_LITERAL1;
				} else {
					type = SparqlTokenType.STRING_LITERAL2;
				}

				token_length_in_chars = 2;
				current++;
				while (current < end && current[0] != begin[0]) {
					if (current[0] == '\\') {
						current++;
						token_length_in_chars++;
						if (current >= end) {
							break;
						}

						switch (current[0]) {
						case '\'':
						case '"':
						case '\\':
						case 'b':
						case 'f':
						case 'n':
						case 'r':
						case 't':
							current++;
							token_length_in_chars++;
							break;
						default:
							throw new SparqlError.PARSE ("%d.%d: invalid escape sequence", line, column + token_length_in_chars);
						}
					} else if (current[0] == '\n') {
						break;
					} else {
						unichar u = ((string) current).get_char_validated ((long) (end - current));
						if (u != (unichar) (-1)) {
							current += u.to_utf8 (null);
							token_length_in_chars++;
						} else {
							current++;
							throw new SparqlError.PARSE ("%d.%d: invalid UTF-8 character", line, column + token_length_in_chars);
						}
					}
				}
				if (current < end && current[0] != '\n') {
					current++;
				} else {
					throw new SparqlError.PARSE ("%d.%d: syntax error, expected %c", line, column + token_length_in_chars, begin[0]);
				}
				break;
			case '^':
				type = SparqlTokenType.NONE;
				if (current < end - 2 && current[0] == current[1]) {
					type = SparqlTokenType.DOUBLE_CIRCUMFLEX;
					current += 2;
				}
				break;
			case '_':
				type = SparqlTokenType.BLANK_NODE;
				current++;
				break;
			default:
				unichar u = ((string) current).get_char_validated ((long) (end - current));
				if (u != (unichar) (-1)) {
					throw new SparqlError.PARSE ("%d.%d: syntax error, unexpected character", line, column);
				} else {
					throw new SparqlError.PARSE ("%d.%d: invalid UTF-8 character", line, column);
				}
			}
		}

		if (token_length_in_chars < 0) {
			column += (int) (current - begin);
		} else {
			column += token_length_in_chars;
		}

		token_end.pos = current;
		token_end.line = line;
		token_end.column = column - 1;

		return type;
	}

	bool matches (char* begin, string keyword) {
		char* keyword_array = keyword;
		for (int i = 0; keyword_array[i] != 0; i++) {
			if (begin[i].toupper () != keyword_array[i]) {
				return false;
			}
		}
		return true;
	}

	bool whitespace () {
		bool found = false;
		while (current < end && current[0].isspace ()) {
			if (current[0] == '\n') {
				line++;
				column = 0;
			}
			found = true;
			current++;
			column++;
		}
		return found;
	}

	bool comment () {
		if (current >= end || current[0] != '#') {
			return false;
		}

		// single-line comment
		// skip until end of line or end of file
		while (current < end && current[0] != '\n') {
			current++;
		}

		return true;
	}

	void space () {
		while (whitespace () || comment ()) {
		}
	}
}

/**
 * Represents a position in a source file.
 */
public struct Tracker.SourceLocation {
	public char* pos;
	public int line;
	public int column;

	public SourceLocation (char* _pos, int _line, int _column) {
		pos = _pos;
		line = _line;
		column = _column;
	}
}

public enum Tracker.SparqlTokenType {
	NONE,
	A,
	AS,
	ASC,
	ASK,
	ATBASE,
	ATPREFIX,
	AVG,
	BASE,
	BLANK_NODE,
	BOUND,
	BY,
	CLOSE_BRACE,
	CLOSE_BRACKET,
	CLOSE_PARENS,
	COLON,
	COMMA,
	CONSTRUCT,
	COUNT,
	DATATYPE,
	DECIMAL,
	DELETE,
	DESC,
	DESCRIBE,
	DISTINCT,
	DIV,
	DOT,
	DOUBLE,
	DOUBLE_CIRCUMFLEX,
	DROP,
	EOF,
	FALSE,
	FILTER,
	FROM,
	GRAPH,
	GROUP,
	GROUP_CONCAT,
	INSERT,
	INTEGER,
	INTO,
	IRI_REF,
	ISIRI,
	ISLITERAL,
	ISURI,
	ISBLANK,
	LANG,
	LANGMATCHES,
	LIMIT,
	MAX,
	MIN,
	MINUS,
	NAMED,
	OFFSET,
	OP_AND,
	OP_EQ,
	OP_GE,
	OP_GT,
	OP_LE,
	OP_LT,
	OP_NE,
	OP_NEG,
	OP_OR,
	OPEN_BRACE,
	OPEN_BRACKET,
	OPEN_PARENS,
	OPTIONAL,
	ORDER,
	PLUS,
	PN_PREFIX,
	PREFIX,
	REDUCED,
	REGEX,
	SAMETERM,
	SELECT,
	SEMICOLON,
	STAR,
	STR,
	STRING_LITERAL1,
	STRING_LITERAL2,
	STRING_LITERAL_LONG1,
	STRING_LITERAL_LONG2,
	SUM,
	TRUE,
	UNION,
	VAR,
	WHERE;

	public weak string to_string () {
		switch (this) {
		case A: return "`a'";
		case AS: return "`AS'";
		case ASC: return "`ASC'";
		case ASK: return "`ASK'";
		case BASE: return "`BASE'";
		case BOUND: return "`BOUND'";
		case BY: return "`BY'";
		case CONSTRUCT: return "`CONSTRUCT'";
		case DATATYPE: return "`DATATYPE'";
		case DECIMAL: return "`DECIMAL'";
		case DELETE: return "`DELETE'";
		case DESC: return "`DESC'";
		case DESCRIBE: return "`DESCRIBE'";
		case DISTINCT: return "`DISTINCT'";
		case DOUBLE: return "`DOUBLE'";
		case DROP: return "`DROP'";
		case EOF: return "`EOF'";
		case FALSE: return "`FALSE'";
		case FILTER: return "`FILTER'";
		case FROM: return "`FROM'";
		case GRAPH: return "`GRAPH'";
		case GROUP: return "`GROUP'";
		case INSERT: return "`INSERT'";
		case INTEGER: return "`INTEGER'";
		case INTO: return "`INTO'";
		case ISIRI: return "`ISIRI'";
		case ISBLANK: return "`ISBLANK'";
		case ISLITERAL: return "`ISLITERAL'";
		case ISURI: return "`ISURI'";
		case LANG: return "`LANG'";
		case LANGMATCHES: return "`LANGMATCHES'";
		case LIMIT: return "`LIMIT'";
		case NAMED: return "`NAMED'";
		case OFFSET: return "`OFFSET'";
		case OPTIONAL: return "`OPTIONAL'";
		case ORDER: return "`ORDER'";
		case PN_PREFIX: return "`PN_PREFIX'";
		case PREFIX: return "`PREFIX'";
		case REDUCED: return "`REDUCED'";
		case REGEX: return "`REGEX'";
		case SAMETERM: return "`SAMETERM'";
		case SELECT: return "`SELECT'";
		case STR: return "`STR'";
		case TRUE: return "`TRUE'";
		case UNION: return "`UNION'";
		case WHERE: return "`WHERE'";
		default: return "unknown token";
		}
	}
}

