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

public class Tracker.TurtleReader : Object {
	SparqlScanner scanner;

	// token buffer
	TokenInfo[] tokens;
	// index of current token in buffer
	int index;
	// number of tokens in buffer
	int size;

	const int BUFFER_SIZE = 32;

	struct TokenInfo {
		public SparqlTokenType type;
		public SourceLocation begin;
		public SourceLocation end;
	}

	enum State {
		INITIAL,
		BOS,
		SUBJECT,
		PREDICATE,
		OBJECT
	}

	State state;

	public string subject { get; private set; }
	public string predicate { get; private set; }
	public string object { get; private set; }
	public bool object_is_uri { get; private set; }

	HashTable<string,string> prefix_map;

	string[] subject_stack;

	int bnodeid = 0;
	// base UUID used for blank nodes
	uchar[] base_uuid;

	MappedFile? mapped_file;

	public TurtleReader (string path) {
		mapped_file = new MappedFile (path, false);
		scanner = new SparqlScanner (mapped_file.get_contents (), mapped_file.get_length ());

		base_uuid = new uchar[16];
		uuid_generate (base_uuid);

		tokens = new TokenInfo[BUFFER_SIZE];
		prefix_map = new HashTable<string,string>.full (str_hash, str_equal, g_free, g_free);
	}

	string generate_bnodeid (string? user_bnodeid) {
		// user_bnodeid is NULL for anonymous nodes
		if (user_bnodeid == null) {
			return ":%d".printf (++bnodeid);
		} else {
			var checksum = new Checksum (ChecksumType.SHA1);
			// base UUID, unique per file
			checksum.update (base_uuid, 16);
			// node ID
			checksum.update ((uchar[]) user_bnodeid, -1);

			string sha1 = checksum.get_string ();

			// generate name based uuid
			return "urn:uuid:%.8s-%.4s-%.4s-%.4s-%.12s".printf (
				sha1, sha1.offset (8), sha1.offset (12), sha1.offset (16), sha1.offset (20));
		}
	}

	inline bool next_token () throws SparqlError {
		index = (index + 1) % BUFFER_SIZE;
		size--;
		if (size <= 0) {
			SourceLocation begin, end;
			SparqlTokenType type = scanner.read_token (out begin, out end);
			tokens[index].type = type;
			tokens[index].begin = begin;
			tokens[index].end = end;
			size = 1;
		}
		return (tokens[index].type != SparqlTokenType.EOF);
	}

	inline SparqlTokenType current () {
		return tokens[index].type;
	}

	inline bool accept (SparqlTokenType type) throws SparqlError {
		if (current () == type) {
			next_token ();
			return true;
		}
		return false;
	}

	bool expect (SparqlTokenType type) throws SparqlError {
		if (accept (type)) {
			return true;
		}

		throw new SparqlError.PARSE ("expected %s", type.to_string ());
	}

	string get_last_string (int strip = 0) {
		int last_index = (index + BUFFER_SIZE - 1) % BUFFER_SIZE;
		return ((string) (tokens[last_index].begin.pos + strip)).ndup ((tokens[last_index].end.pos - tokens[last_index].begin.pos - 2 * strip));
	}

	public bool next () throws SparqlError {
		while (true) {
			switch (state) {
			case State.INITIAL:
				next_token ();
				state = State.BOS;
				continue;
			case State.BOS:
				// begin of statement
				if (accept (SparqlTokenType.ATPREFIX)) {
					string ns = "";
					if (accept (SparqlTokenType.PN_PREFIX)) {
					       ns = get_last_string ();
					}
					expect (SparqlTokenType.COLON);
					expect (SparqlTokenType.IRI_REF);
					string uri = get_last_string (1);
					prefix_map.insert (ns, uri);
					expect (SparqlTokenType.DOT);
					continue;
				} else if (accept (SparqlTokenType.ATBASE)) {
					expect (SparqlTokenType.IRI_REF);
					expect (SparqlTokenType.DOT);
					continue;
				} else if (current () == SparqlTokenType.EOF) {
					return false;
				}
				// parse subject
				if (accept (SparqlTokenType.IRI_REF)) {
					subject = get_last_string (1);
					state = State.SUBJECT;
					continue;
				} else if (accept (SparqlTokenType.PN_PREFIX)) {
					// prefixed name with namespace foo:bar
					string ns = get_last_string ();
					expect (SparqlTokenType.COLON);
					subject = prefix_map.lookup (ns) + get_last_string ().substring (1);
					state = State.SUBJECT;
					continue;
				} else if (accept (SparqlTokenType.COLON)) {
					// prefixed name without namespace :bar
					subject = prefix_map.lookup ("") + get_last_string ().substring (1);
					state = State.SUBJECT;
					continue;
				} else if (accept (SparqlTokenType.BLANK_NODE)) {
					// _:foo
					expect (SparqlTokenType.COLON);
					subject = generate_bnodeid (get_last_string ().substring (1));
					state = State.SUBJECT;
					continue;
				} else {
					// TODO throw error
					return false;
				}
			case State.SUBJECT:
				// parse predicate
				if (accept (SparqlTokenType.IRI_REF)) {
					predicate = get_last_string (1);
					state = State.PREDICATE;
					continue;
				} else if (accept (SparqlTokenType.PN_PREFIX)) {
					string ns = get_last_string ();
					expect (SparqlTokenType.COLON);
					predicate = prefix_map.lookup (ns) + get_last_string ().substring (1);
					state = State.PREDICATE;
					continue;
				} else if (accept (SparqlTokenType.COLON)) {
					predicate = prefix_map.lookup ("") + get_last_string ().substring (1);
					state = State.PREDICATE;
					continue;
				} else if (accept (SparqlTokenType.A)) {
					predicate = "http://www.w3.org/1999/02/22-rdf-syntax-ns#type";
					state = State.PREDICATE;
					continue;
				} else {
					// TODO throw error
					return false;
				}
			case State.PREDICATE:
				// parse object
				if (accept (SparqlTokenType.IRI_REF)) {
					object = get_last_string (1);
					object_is_uri = true;
					state = State.OBJECT;
					return true;
				} else if (accept (SparqlTokenType.PN_PREFIX)) {
					// prefixed name with namespace foo:bar
					string ns = get_last_string ();
					expect (SparqlTokenType.COLON);
					object = prefix_map.lookup (ns) + get_last_string ().substring (1);
					object_is_uri = true;
					state = State.OBJECT;
					return true;
				} else if (accept (SparqlTokenType.COLON)) {
					// prefixed name without namespace :bar
					object = prefix_map.lookup ("") + get_last_string ().substring (1);
					object_is_uri = true;
					state = State.OBJECT;
					return true;
				} else if (accept (SparqlTokenType.BLANK_NODE)) {
					// _:foo
					expect (SparqlTokenType.COLON);
					object = generate_bnodeid (get_last_string ().substring (1));
					object_is_uri = true;
					state = State.OBJECT;
					return true;
				} else if (accept (SparqlTokenType.OPEN_BRACKET)) {
					// begin of anonymous blank node
					subject_stack += subject;
					subject = generate_bnodeid (null);
					state = State.SUBJECT;
					continue;
				} else if (accept (SparqlTokenType.CLOSE_BRACKET)) {
					// end of anonymous blank node
					subject = subject_stack[subject_stack.length - 1];
					subject_stack.length--;
					state = State.OBJECT;
					continue;
				} else if (accept (SparqlTokenType.STRING_LITERAL1) || accept (SparqlTokenType.STRING_LITERAL2)) {
					var sb = new StringBuilder ();

					string s = get_last_string (1);
					string* p = s;
					string* end = p + s.size ();
					while ((long) p < (long) end) {
						string* q = Posix.strchr (p, '\\');
						if (q == null) {
							sb.append_len (p, (long) (end - p));
							p = end;
						} else {
							sb.append_len (p, (long) (q - p));
							p = q + 1;
							switch (((char*) p)[0]) {
							case '\'':
							case '"':
							case '\\':
								sb.append_c (((char*) p)[0]);
								break;
							case 'b':
								sb.append_c ('\b');
								break;
							case 'f':
								sb.append_c ('\f');
								break;
							case 'n':
								sb.append_c ('\n');
								break;
							case 'r':
								sb.append_c ('\r');
								break;
							case 't':
								sb.append_c ('\t');
								break;
							}
							p++;
						}
					}
					object = sb.str;
					object_is_uri = false;
					state = State.OBJECT;

					if (accept (SparqlTokenType.DOUBLE_CIRCUMFLEX)) {
						if (!accept (SparqlTokenType.IRI_REF)) {
							accept (SparqlTokenType.PN_PREFIX);
							expect (SparqlTokenType.COLON);
						}
					}

					return true;
				} else if (accept (SparqlTokenType.STRING_LITERAL_LONG1) || accept (SparqlTokenType.STRING_LITERAL_LONG2)) {
					object = get_last_string (3);
					object_is_uri = false;
					state = State.OBJECT;

					if (accept (SparqlTokenType.DOUBLE_CIRCUMFLEX)) {
						if (!accept (SparqlTokenType.IRI_REF)) {
							accept (SparqlTokenType.PN_PREFIX);
							expect (SparqlTokenType.COLON);
						}
					}

					return true;
				} else if (accept (SparqlTokenType.INTEGER) || accept (SparqlTokenType.DECIMAL) || accept (SparqlTokenType.DOUBLE) || accept (SparqlTokenType.TRUE) || accept (SparqlTokenType.FALSE)) {
					object = get_last_string ();
					object_is_uri = false;
					state = State.OBJECT;
					return true;
				} else {
					// TODO throw error
					return false;
				}
			case State.OBJECT:
				if (accept (SparqlTokenType.COMMA)) {
					state = state.PREDICATE;
					continue;
				} else if (accept (SparqlTokenType.SEMICOLON)) {
					if (accept (SparqlTokenType.DOT)) {
						// semicolon before dot is allowed in both, SPARQL and Turtle
						state = State.BOS;
						continue;
					}
					state = state.SUBJECT;
					continue;
				} else if (accept (SparqlTokenType.DOT)) {
					state = State.BOS;
					continue;
				} else {
					// TODO throw error
					return false;
				}
			}
		}
	}

	public static void load (string path) {
		try {
			Data.begin_transaction ();

			var reader = new TurtleReader (path);
			while (reader.next ()) {
				if (reader.object_is_uri) {
					Data.insert_statement_with_uri (reader.subject, reader.predicate, reader.object);
				} else {
					Data.insert_statement_with_string (reader.subject, reader.predicate, reader.object);
				}
			}
		} finally {
			Data.commit_transaction ();
		}
	}

	[CCode (cname = "uuid_generate")]
	public extern static void uuid_generate ([CCode (array_length = false)] uchar[] uuid);
}

