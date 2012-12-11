jade = require "../"
assert = require "assert"
fs = require "fs"

# Shortcut
fixture = (path) ->
	fs.readFileSync __dirname + "/fixtures/" + path, "utf8"
render = (str, options) ->
	fn = jade.compile(str, options)
	fn options

assert.render = (jade, html, options) ->
	path = __dirname + "/fixtures/" + jade
	opts =
		pretty: true
		filename: path

	jade = fixture(jade)
	html = fixture(html).trim()
	for key of options
		opts[key] = options[key]
	res = render(jade, opts).trim()
	if res isnt html
		console.error()
		console.error path
		console.error "\n\u001b[31mexpected:\u001b[m "
		console.error html
		console.error "\n\u001b[31mgot:\u001b[m "
		console.error res
		process.exit 1

module.exports =
	"test .version": ->
		assert.ok /^\d+\.\d+\.\d+$/.test(jade.version), "Invalid version format"

	"test exports": ->
		assert.equal "object", typeof jade.selfClosing, "exports.selfClosing missing"
		assert.equal "object", typeof jade.doctypes, "exports.doctypes missing"
		assert.equal "object", typeof jade.filters, "exports.filters missing"
		assert.equal "object", typeof jade.utils, "exports.utils missing"
		assert.equal "function", typeof jade.Compiler, "exports.Compiler missing"

	"test doctypes": ->
		assert.equal "<?xml version=\"1.0\" encoding=\"utf-8\" ?>", render("!!! xml")
		assert.equal "<!DOCTYPE html>", render("doctype html")
		assert.equal "<!DOCTYPE foo bar baz>", render("doctype foo bar baz")
		assert.equal "<!DOCTYPE html>", render("!!! 5")
		assert.equal "<!DOCTYPE html>", render("!!!",
			doctype: "html"
		)
		assert.equal "<!DOCTYPE html>", render("!!! html",
			doctype: "xml"
		)
		assert.equal "<html></html>", render("html")
		assert.equal "<!DOCTYPE html><html></html>", render("html",
			doctype: "html"
		)

	"test Buffers": ->
		assert.equal "<p>foo</p>", render(new Buffer("p foo"))

	"test line endings": ->
		str = ["p", "div", "img"].join("\r\n")
		html = ["<p></p>", "<div></div>", "<img/>"].join("")
		assert.equal html, render(str)
		str = ["p", "div", "img"].join("\r")
		html = ["<p></p>", "<div></div>", "<img/>"].join("")
		assert.equal html, render(str)
		str = ["p", "div", "img"].join("\r\n")
		html = ["<p></p>", "<div></div>", "<img>"].join("")
		assert.equal html, render(str,
			doctype: "html"
		)

	"test single quotes": ->
		assert.equal "<p>'foo'</p>", render("p 'foo'")
		assert.equal "<p>'foo'\n</p>", render("p\n  | 'foo'")
		assert.equal "<a href=\"/foo\"></a>", render("- var path = 'foo';\na(href='/' + path)")

	"test block-expansion": ->
		assert.equal "<li><a>foo</a></li><li><a>bar</a></li><li><a>baz</a></li>", render("li: a foo\nli: a bar\nli: a baz")
		assert.equal "<li class=\"first\"><a>foo</a></li><li><a>bar</a></li><li><a>baz</a></li>", render("li.first: a foo\nli: a bar\nli: a baz")
		assert.equal "<div class=\"foo\"><div class=\"bar\">baz</div></div>", render(".foo: .bar baz")

	"test case statement": ->
		assert.equal fixture("case.html"), render(fixture("case.jade"))
		assert.equal fixture("case-blocks.html"), render(fixture("case-blocks.jade"))

	"test tags": ->
		str = ["p", "div", "img"].join("\n")
		html = ["<p></p>", "<div></div>", "<img/>"].join("")
		assert.equal html, render(str), "Test basic tags"
		assert.equal "<fb:foo-bar></fb:foo-bar>", render("fb:foo-bar"), "Test hyphens"
		assert.equal "<div class=\"something\"></div>", render("div.something"), "Test classes"
		assert.equal "<div id=\"something\"></div>", render("div#something"), "Test ids"
		assert.equal "<div class=\"something\"></div>", render(".something"), "Test stand-alone classes"
		assert.equal "<div id=\"something\"></div>", render("#something"), "Test stand-alone ids"
		assert.equal "<div id=\"foo\" class=\"bar\"></div>", render("#foo.bar")
		assert.equal "<div id=\"foo\" class=\"bar\"></div>", render(".bar#foo")
		assert.equal "<div id=\"foo\" class=\"bar\"></div>", render("div#foo(class=\"bar\")")
		assert.equal "<div id=\"foo\" class=\"bar\"></div>", render("div(class=\"bar\")#foo")
		assert.equal "<div id=\"bar\" class=\"foo\"></div>", render("div(id=\"bar\").foo")
		assert.equal "<div class=\"foo bar baz\"></div>", render("div.foo.bar.baz")
		assert.equal "<div class=\"foo bar baz\"></div>", render("div(class=\"foo\").bar.baz")
		assert.equal "<div class=\"foo bar baz\"></div>", render("div.foo(class=\"bar\").baz")
		assert.equal "<div class=\"foo bar baz\"></div>", render("div.foo.bar(class=\"baz\")")
		assert.equal "<div class=\"a-b2\"></div>", render("div.a-b2")
		assert.equal "<div class=\"a_b2\"></div>", render("div.a_b2")
		assert.equal "<fb:user></fb:user>", render("fb:user")
		assert.equal "<fb:user:role></fb:user:role>", render("fb:user:role")
		assert.equal "<colgroup><col class=\"test\"/></colgroup>", render("colgroup\n  col.test")

	"test nested tags": ->
		str = ["ul", "  li a", "  li b", "  li", "    ul", "      li c", "      li d", "  li e"].join("\n")
		html = ["<ul>", "<li>a</li>", "<li>b</li>", "<li><ul><li>c</li><li>d</li></ul></li>", "<li>e</li>", "</ul>"].join("")
		assert.equal html, render(str)
		str = ["a(href=\"#\")", "  | foo ", "  | bar ", "  | baz"].join("\n")
		assert.equal "<a href=\"#\">foo \nbar \nbaz\n</a>", render(str)
		str = ["ul", "  li one", "  ul", "    | two", "    li three"].join("\n")
		html = ["<ul>", "<li>one</li>", "<ul>two\n", "<li>three</li>", "</ul>", "</ul>"].join("")
		assert.equal html, render(str)

	"test variable length newlines": ->
		str = """
			ul
			  li a
			  
			  li b
			 
			         
			  li
			    ul
			      li c
			
			      li d
			  li e"
		"""

		html = """
			<ul>
			<li>a</li>
			<li>b</li>
			<li><ul><li>c</li><li>d</li></ul></li>
			<li>e</li>
			</ul>
		"""
		assert.equal html,
		render(str)

	"test tab conversion": ->
		str = """
			ul
			\tli a
			\t
			\tli b
			\t\t
			\t\t\t\t\t\t
			\tli
			\t\tul
			\t\t\tli c
			
			\t\t\tli d
			\tli e
		"""
		html =
			'<ul>
			<li>a</li>
			<li>b</li>
			<li><ul><li>c</li><li>d</li></ul></li>
			<li>e</li>
			</ul>'

		assert.equal html, render(str)

	"test newlines": ->
		str = [
			"ul",
			"  li a",
			"  ",
			"    ",
			"",
			" ",
			"  li b",
			"  li",
			"    ",
			"        ",
			" ",
			"    ul",
			"      ",
			"      li c",
			"      li d",
			"  li e"
		].join("\n")

		html = ["<ul>", "<li>a</li>", "<li>b</li>", "<li><ul><li>c</li><li>d</li></ul></li>", "<li>e</li>", "</ul>"].join("")
		assert.equal html, render(str)
		str = ["html", " ", "  head", "    != \"test\"", "  ", "  ", "  ", "  body"].join("\n")
		html = ["<html>", "<head>", "test", "</head>", "<body></body>", "</html>"].join("")
		assert.equal html, render(str)
		assert.equal "<foo></foo>something<bar></bar>", render("foo\n= \"something\"\nbar")
		assert.equal "<foo></foo>something<bar></bar>else", render("foo\n= \"something\"\nbar\n= \"else\"")

	"test text": ->
		assert.equal "foo\nbar\nbaz\n", render("| foo\n| bar\n| baz")
		assert.equal "foo \nbar \nbaz\n", render("| foo \n| bar \n| baz")
		assert.equal "(hey)\n", render("| (hey)")
		assert.equal "some random text\n", render("| some random text")
		assert.equal "  foo\n", render("|   foo")
		assert.equal "  foo  \n", render("|   foo  ")
		assert.equal "  foo  \n bar    \n", render("|   foo  \n|  bar    ")

	"test pipe-less text": ->
		assert.equal "<pre><code><foo></foo><bar></bar></code></pre>", render("pre\n  code\n    foo\n\n    bar")
		assert.equal "<p>foo\n\nbar\n</p>", render("p.\n  foo\n\n  bar")
		assert.equal "<p>foo\n\n\n\nbar\n</p>", render("p.\n  foo\n\n\n\n  bar")
		assert.equal "<p>foo\n  bar\nfoo\n</p>", render("p.\n  foo\n    bar\n  foo")
		assert.equal "<script>s.parentNode.insertBefore(g,s)\n</script>", render("script\n  s.parentNode.insertBefore(g,s)\n")
		assert.equal "<script>s.parentNode.insertBefore(g,s)\n</script>", render("script\n  s.parentNode.insertBefore(g,s)")

	"test tag text": ->
		assert.equal "<p>some random text</p>", render("p some random text")
		assert.equal "<p>click\n<a>Google</a>.\n</p>", render("p\n  | click\n  a Google\n  | .")
		assert.equal "<p>(parens)</p>", render("p (parens)")
		assert.equal "<p foo=\"bar\">(parens)</p>", render("p(foo=\"bar\") (parens)")
		assert.equal "<option value=\"\">-- (optional) foo --</option>", render("option(value=\"\") -- (optional) foo --")

	"test tag text block": ->
		assert.equal "<p>foo \nbar \nbaz\n</p>", render("p\n  | foo \n  | bar \n  | baz")
		assert.equal "<label>Password:\n<input/></label>", render("label\n  | Password:\n  input")
		assert.equal "<label>Password:<input/></label>", render("label Password:\n  input")

	"test tag text interpolation": ->
		assert.equal "yo, jade is cool\n", render("| yo, #{name} is cool\n",
			name: "jade"
		)
		assert.equal "<p>yo, jade is cool</p>", render("p yo, #{name} is cool",
			name: "jade"
		)
		assert.equal 'yo, jade is cool\n', render('| yo, #{name || \"jade\"} is cool',
			name: null
		)
		assert.equal 'yo, \'jade\' is cool\n', render('| yo, #{name || \"\'jade\'\"} is cool',
			name: null
		)
		assert.equal "foo &lt;script&gt; bar\n", render("| foo #{code} bar",
			code: "<script>"
		)
		assert.equal "foo <script> bar\n", render("| foo !{code} bar",
			code: "<script>"
		)

	"test flexible indentation": ->
		assert.equal "<html><body><h1>Wahoo</h1><p>test</p></body></html>", render("html\n  body\n   h1 Wahoo\n   p test")

	"test interpolation values": ->
		assert.equal "<p>Users: 15</p>", render("p Users: #{15}")
		assert.equal "<p>Users: </p>", render("p Users: #{null}")
		assert.equal "<p>Users: </p>", render("p Users: #{undefined}")
		assert.equal "<p>Users: none</p>", render('p Users: #{undefined || "none"}')
		assert.equal "<p>Users: 0</p>", render("p Users: #{0}")
		assert.equal "<p>Users: false</p>", render("p Users: #{false}")

	"test html 5 mode": ->
		assert.equal "<!DOCTYPE html><input type=\"checkbox\" checked>", render("!!! 5\ninput(type=\"checkbox\", checked)")
		assert.equal "<!DOCTYPE html><input type=\"checkbox\" checked>", render("!!! 5\ninput(type=\"checkbox\", checked=true)")
		assert.equal "<!DOCTYPE html><input type=\"checkbox\">", render("!!! 5\ninput(type=\"checkbox\", checked= false)")

	"test colons option": ->
		assert.equal "<a href=\"/bar\"></a>", render("a(href:\"/bar\")",
			colons: true
		)

	"test class attr array": ->
		assert.equal "<body class=\"foo bar baz\"></body>", render("body(class=[\"foo\", \"bar\", \"baz\"])")

	"test attr interpolation": ->
		
		# Test single quote interpolation
		assert.equal "<a href=\"/user/12\">tj</a>", render("a(href='/user/#{id}') #{name}",
			name: "tj"
			id: 12
		)
		assert.equal "<a href=\"/user/12-tj\">tj</a>", render("a(href='/user/#{id}-#{name}') #{name}",
			name: "tj"
			id: 12
		)
		assert.equal "<a href=\"/user/&lt;script&gt;\">tj</a>", render("a(href='/user/#{id}') #{name}",
			name: "tj"
			id: "<script>"
		)
		
		# Test double quote interpolation
		assert.equal "<a href=\"/user/13\">ds</a>", render("a(href=\"/user/#{id}\") #{name}",
			name: "ds"
			id: 13
		)
		assert.equal "<a href=\"/user/13-ds\">ds</a>", render("a(href=\"/user/#{id}-#{name}\") #{name}",
			name: "ds"
			id: 13
		)
		assert.equal "<a href=\"/user/&lt;script&gt;\">ds</a>", render("a(href=\"/user/#{id}\") #{name}",
			name: "ds"
			id: "<script>"
		)

	"test attr parens": ->
		assert.equal "<p foo=\"bar\">baz</p>", render("p(foo=(((\"bar\"))))= (((\"baz\")))")

	"test code attrs": ->
		assert.equal "<p></p>", render("p(id= name)",
			name: undefined
		)
		assert.equal "<p></p>", render("p(id= name)",
			name: null
		)
		assert.equal "<p></p>", render("p(id= name)",
			name: false
		)
		assert.equal "<p id=\"\"></p>", render("p(id= name)",
			name: ""
		)
		assert.equal "<p id=\"tj\"></p>", render("p(id= name)",
			name: "tj"
		)
		assert.equal "<p id=\"default\"></p>", render("p(id= name || \"default\")",
			name: null
		)
		assert.equal "<p id=\"something\"></p>", render("p(id= 'something')",
			name: null
		)
		assert.equal "<p id=\"something\"></p>", render("p(id = 'something')",
			name: null
		)
		assert.equal "<p id=\"foo\"></p>", render("p(id= (true ? 'foo' : 'bar'))")
		assert.equal "<option value=\"\">Foo</option>", render("option(value='') Foo")

	"test code attrs class": ->
		assert.equal "<p class=\"tj\"></p>", render("p(class= name)",
			name: "tj"
		)
		assert.equal "<p class=\"tj\"></p>", render("p( class= name )",
			name: "tj"
		)
		assert.equal "<p class=\"default\"></p>", render("p(class= name || \"default\")",
			name: null
		)
		assert.equal "<p class=\"foo default\"></p>", render("p.foo(class= name || \"default\")",
			name: null
		)
		assert.equal "<p class=\"default foo\"></p>", render("p(class= name || \"default\").foo",
			name: null
		)
		assert.equal "<p id=\"default\"></p>", render("p(id = name || \"default\")",
			name: null
		)
		assert.equal "<p id=\"user-1\"></p>", render("p(id = \"user-\" + 1)")
		assert.equal "<p class=\"user-1\"></p>", render("p(class = \"user-\" + 1)")

	"test code buffering": ->
		assert.equal "<p></p>", render("p= null")
		assert.equal "<p></p>", render("p= undefined")
		assert.equal "<p>0</p>", render("p= 0")
		assert.equal "<p>false</p>", render("p= false")

	"test script text": ->
		str = ["script", "  p foo", "", "script(type=\"text/template\")", "  p foo", "", "script(type=\"text/template\").", "  p foo"].join("\n")
		html = ["<script>p foo\n\n</script>", "<script type=\"text/template\"><p>foo</p></script>", "<script type=\"text/template\">p foo\n</script>"].join("")
		assert.equal html, render(str)

	"test comments": ->
		
		# Regular
		str = ["//foo", "p bar"].join("\n")
		html = ["<!--foo-->", "<p>bar</p>"].join("")
		assert.equal html, render(str)
		
		# Arbitrary indentation
		str = ["     //foo", "p bar"].join("\n")
		html = ["<!--foo-->", "<p>bar</p>"].join("")
		assert.equal html, render(str)
		
		# Between tags
		str = ["p foo", "// bar ", "p baz"].join("\n")
		html = ["<p>foo</p>", "<!-- bar -->", "<p>baz</p>"].join("")
		assert.equal html, render(str)
		
		# Quotes
		str = "<!-- script(src: '/js/validate.js') -->"
		js = "// script(src: '/js/validate.js') "
		assert.equal str, render(js)

	"test unbuffered comments": ->
		str = ["//- foo", "p bar"].join("\n")
		html = ["<p>bar</p>"].join("")
		assert.equal html, render(str)
		str = ["p foo", "//- bar ", "p baz"].join("\n")
		html = ["<p>foo</p>", "<p>baz</p>"].join("")
		assert.equal html, render(str)

	"test literal html": ->
		assert.equal "<!--[if IE lt 9]>weeee<![endif]-->\n", render("<!--[if IE lt 9]>weeee<![endif]-->")

	"test code": ->
		assert.equal "test", render("!= \"test\"")
		assert.equal "test", render("= \"test\"")
		assert.equal "test", render("- var foo = \"test\"\n=foo")
		assert.equal "foo\n<em>test</em>bar\n", render("- var foo = \"test\"\n| foo\nem= foo\n| bar")
		assert.equal "test<h2>something</h2>", render("!= \"test\"\nh2 something")
		str = ["- var foo = \"<script>\";", "= foo", "!= foo"].join("\n")
		html = ["&lt;script&gt;", "<script>"].join("")
		assert.equal html, render(str)
		str = ["- var foo = \"<script>\";", "- if (foo)", "  p= foo"].join("\n")
		html = ["<p>&lt;script&gt;</p>"].join("")
		assert.equal html, render(str)
		str = ["- var foo = \"<script>\";", "- if (foo)", "  p!= foo"].join("\n")
		html = ["<p><script></p>"].join("")
		assert.equal html, render(str)
		str = ["- var foo;", "- if (foo)", "  p.hasFoo= foo", "- else", "  p.noFoo no foo"].join("\n")
		html = ["<p class=\"noFoo\">no foo</p>"].join("")
		assert.equal html, render(str)
		str = ["- var foo;", "- if (foo)", "  p.hasFoo= foo", "- else if (true)", "  p kinda foo", "- else", "  p.noFoo no foo"].join("\n")
		html = ["<p>kinda foo</p>"].join("")
		assert.equal html, render(str)
		str = ["p foo", "= \"bar\""].join("\n")
		html = ["<p>foo</p>bar"].join("")
		assert.equal html, render(str)
		str = ["title foo", "- if (true)", "  p something"].join("\n")
		html = ["<title>foo</title><p>something</p>"].join("")
		assert.equal html, render(str)
		str = ["foo", "  bar= \"bar\"", "    baz= \"baz\""].join("\n")
		html = ["<foo>", "<bar>bar", "<baz>baz</baz>", "</bar>", "</foo>"].join("")
		assert.equal html, render(str)

	"test - each": ->
		
		# Array
		str = ["- var items = [\"one\", \"two\", \"three\"];", "- each item in items", "  li= item"].join("\n")
		html = ["<li>one</li>", "<li>two</li>", "<li>three</li>"].join("")
		assert.equal html, render(str)
		
		# Any enumerable (length property)
		str = ["- var jQuery = { length: 3, 0: 1, 1: 2, 2: 3 };", "- each item in jQuery", "  li= item"].join("\n")
		html = ["<li>1</li>", "<li>2</li>", "<li>3</li>"].join("")
		assert.equal html, render(str)
		
		# Empty array
		str = ["- var items = [];", "- each item in items", "  li= item"].join("\n")
		assert.equal "", render(str)
		
		# Object
		str = ["- var obj = { foo: \"bar\", baz: \"raz\" };", "- each val in obj", "  li= val"].join("\n")
		html = ["<li>bar</li>", "<li>raz</li>"].join("")
		assert.equal html, render(str)
		
		# Complex
		str = ["- var obj = { foo: \"bar\", baz: \"raz\" };", "- each key in Object.keys(obj)", "  li= key"].join("\n")
		html = ["<li>foo</li>", "<li>baz</li>"].join("")
		assert.equal html, render(str)
		
		# Keys
		str = ["- var obj = { foo: \"bar\", baz: \"raz\" };", "- each val, key in obj", "  li #{key}: #{val}"].join("\n")
		html = ["<li>foo: bar</li>", "<li>baz: raz</li>"].join("")
		assert.equal html, render(str)
		
		# Nested
		str = ["- var users = [{ name: \"tj\" }]", "- each user in users", "  - each val, key in user", "    li #{key} #{val}"].join("\n")
		html = ["<li>name tj</li>"].join("")
		assert.equal html, render(str)
		str = ["- var users = [\"tobi\", \"loki\", \"jane\"]", "each user in users", "  li= user"].join("\n")
		html = ["<li>tobi</li>", "<li>loki</li>", "<li>jane</li>"].join("")
		assert.equal html, render(str)
		str = ["- var users = [\"tobi\", \"loki\", \"jane\"]", "for user in users", "  li= user"].join("\n")
		html = ["<li>tobi</li>", "<li>loki</li>", "<li>jane</li>"].join("")
		assert.equal html, render(str)

	"test if": ->
		str = ["- var users = [\"tobi\", \"loki\", \"jane\"]", "if users.length", "  p users: #{users.length}"].join("\n")
		assert.equal "<p>users: 3</p>", render(str)
		assert.equal "<iframe foo=\"bar\"></iframe>", render("iframe(foo=\"bar\")")

	"test unless": ->
		str = ["- var users = [\"tobi\", \"loki\", \"jane\"]", "unless users.length", "  p no users"].join("\n")
		assert.equal "", render(str)
		str = ["- var users = []", "unless users.length", "  p no users"].join("\n")
		assert.equal "<p>no users</p>", render(str)

	"test else": ->
		str = ["- var users = []", "if users.length", "  p users: #{users.length}", "else", "  p users: none"].join("\n")
		assert.equal "<p>users: none</p>", render(str)

	"test else if": ->
		str = ["- var users = [\"tobi\", \"jane\", \"loki\"]", "for user in users", "  if user == \"tobi\"", "    p awesome #{user}", "  else if user == \"jane\"", "    p lame #{user}", "  else", "    p #{user}"].join("\n")
		assert.equal "<p>awesome tobi</p><p>lame jane</p><p>loki</p>", render(str)

	"test mixins": ->
		assert.render "mixins.jade", "mixins.html"

	"test conditional comments": ->
		assert.render "conditional-comment.jade", "conditional-comment.html"

	"test inheritance": ->
		assert.render "users.jade", "users.html",
			users: ["tobi", "loki", "jane"]

		assert.render "pet-page.jade", "pet.html",
			superCool: false
			name: "tobi"
			age: 1
			species: "ferret"

		assert.render "pet-page.jade", "super-pet.html",
			superCool: true
			name: "tobi"
			age: 1
			species: "ferret"


	"test block append": ->
		assert.render "append/page.jade", "append/page.html"
		assert.render "append-without-block/page.jade", "append/page.html"

	"test block prepend": ->
		assert.render "prepend/page.jade", "prepend/page.html"
		assert.render "prepend-without-block/page.jade", "prepend/page.html"

	"test include literal": ->
		assert.render "include-html.jade", "include-html.html"
		assert.render "include-only-text.jade", "include-only-text.html"
		assert.render "include-with-text.jade", "include-with-text.html"

	"test yield": ->
		assert.render "yield.jade", "yield.html"
		assert.render "yield-title.jade", "yield-title.html"
		assert.render "yield-before-conditional.jade", "yield-before-conditional.html"

	"test include": ->
		str = ["html", "  head", "    include fixtures/test.css"].join("\n")
		assert.equal "<html><head>body {\n  color: black;\n}</head></html>", render(str,
			filename: __dirname + "/jade.test.js"
		)

	"test include block": ->
		str = ["html", "  head", "    include fixtures/scripts", "      scripts(src=\"/app.js\")"].join("\n")
		assert.equal(
			'<html><head><script src="/jquery.js"></script><script src="/caustic.js"></script><scripts src="/app.js"></scripts></head></html>',
			render(
				str,
				filename: __dirname + "/jade.test.js"
			)
		)

	"test .render(str, fn)": ->
		jade.render "p foo bar", (err, str) ->
			assert.ok not err
			assert.equal "<p>foo bar</p>", str


	"test .render(str, options, fn)": ->
		jade.render "p #{foo}",
			foo: "bar"
		, (err, str) ->
			assert.ok not err
			assert.equal "<p>bar</p>", str


	"test .render(str, options, fn) cache": ->
		jade.render "p bar",
			cache: true
		, (err, str) ->
			assert.ok /the "filename" option is required for caching/.test(err.message)

		jade.render "p foo bar",
			cache: true
			filename: "test"
		, (err, str) ->
			assert.ok not err
			assert.equal "<p>foo bar</p>", str


	"test .compile()": ->
		fn = jade.compile("p foo")
		assert.equal "<p>foo</p>", fn()

	"test .compile() locals": ->
		fn = jade.compile("p= foo")
		assert.equal "<p>bar</p>", fn(foo: "bar")

	"test .compile() no debug": ->
		fn = jade.compile("p foo\np #{bar}",
			compileDebug: false
		)
		assert.equal "<p>foo</p><p>baz</p>", fn(bar: "baz")

	"test .compile() no debug and global helpers": ->
		fn = jade.compile("p foo\np #{bar}",
			compileDebug: false
			helpers: "global"
		)
		assert.equal "<p>foo</p><p>baz</p>", fn(bar: "baz")

	"test null attrs on tag": ->
		tag = new jade.nodes.Tag("a")
		name = "href"
		val = "\"/\""
		tag.setAttribute name, val
		assert.equal tag.getAttribute(name), val
		tag.removeAttribute name
		assert.ok not tag.getAttribute(name)

	"test assignment": ->
		assert.equal "<div>5</div>", render("a = 5;\ndiv= a")
		assert.equal "<div>5</div>", render("a = 5\ndiv= a")
		assert.equal "<div>foo bar baz</div>", render("a = \"foo bar baz\"\ndiv= a")
		assert.equal "<div>5</div>", render("a = 5      \ndiv= a")
		assert.equal "<div>5</div>", render("a = 5      ; \ndiv= a")
		fn = jade.compile("test = local\np=test")
		assert.equal "<p>bar</p>", fn(local: "bar")