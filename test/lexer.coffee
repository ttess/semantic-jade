Lexer = require '../lib/lexer'

#shortcut
stringify = (variable) ->
	JSON.stringify(variable, null, '\t')

tokenize = (str) ->
	test_lexer = new Lexer(str)
	tokens = []
	while (token = test_lexer.next()).type isnt 'eos'
		tokens.push(token)

	return tokens
	

describe 'Lexer.attrs()', ->
	it 'should recognize text attrs', ->
		stringify(
			tokenize('''
			a(
				foo="bar"
				bar='baz'
				interpolate='#{nope}'
			)
			''')[1].val
		).should.equal(
			stringify(
				attrs:
					foo: '\"bar\"'
					bar: '\'baz\''
					interpolate: '\'#{nope}\''
				escape:
					foo: true
					bar: true
					interpolate: true
			)
		)

	it 'should recognize boolean attrs', ->
		stringify(
			tokenize('''
			a(
				checked
				blah=true
			)
			''')[1].val
		).should.equal(
			stringify(
				attrs:
					checked: 'true'
					blah: 'true'
				escape:
					checked: true
					blah: true
			)
		)

	it 'should recognize data attrs', ->
		stringify(
			tokenize('''
			a(
				data={semantic: 'jade'}
				more_data=['semantic', 'jade']
			)
			''')[1].val
		).should.equal(
			stringify(
				attrs:
					data: '{semantic: \'jade\'}'
					more_data: '[\'semantic\', \'jade\']'
				escape:
					data: true
					more_data: true
			)
		)

describe 'Lexer', ->
	it 'should tokenize shorthand ids', ->

		stringify(tokenize('''
			a#an_ID
			#another-id
			p#MoreID()
		''')).should.equal(
			stringify([
				{type: "tag", line: 1, val: "a", selfClosing: false}
				{type: "id", line: 1, val: "an_ID"}
				{type: "newline", line: 2}
				{type: "id", line: 2, val: "another-id"}
				{type: "newline", line: 3}
				{type: "tag", line: 3, val: "p", selfClosing: false}
				{type: "id", line: 3, val: "MoreID"}
			])
		)

	it 'should tokenize shorthand classes', ->

		stringify(tokenize('''
			a.a_class
			.another-class
			p.MoreClass()
		''')).should.equal(
			stringify([
				{type: "tag", line: 1, val: "a", selfClosing: false}
				{type: "class", line: 1, val: "a_class"}
				{type: "newline", line: 2}
				{type: "class", line: 2, val: "another-class"}
				{type: "newline", line: 3}
				{type: "tag", line: 3, val: "p", selfClosing: false}
				{type: "class", line: 3, val: "MoreClass"}
			])
		)