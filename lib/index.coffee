#Module dependencies
require "coffee-script"
Parser = require("./parser")
Lexer = require("./lexer")
Compiler = require("./compiler")
runtime = require("./runtime")

# if node
fs = require("fs")
# end

#Expose self closing tags
exports.selfClosing = require("./self-closing")

#Default supported doctypes
exports.doctypes = require("./doctypes")

#Text filters
exports.filters = require("./filters")

#Utilities
exports.utils = require("./utils")

#Expose `Compiler`
exports.Compiler = Compiler

#Expose `Parser`
exports.Parser = Parser

#Expose `Lexer`
exports.Lexer = Lexer

#Nodes
exports.nodes = require("./nodes")

#Jade runtime helpers
exports.runtime = runtime

#Template function cache
exports.cache = {}

###
Parse the given `str` of jade and return a function body.

@param {String} str
@param {Object} options
@return {String}
@api private
###
parse = (str, options) ->
	try
		
		# Parse
		parser = new Parser(str, options.filename, options)
		compiler = undefined
		
		# Compile
		if typeof (options.compiler) is "undefined"
			compiler = new Compiler(parser.parse(), options)
		else
			compiler = new options.compiler(parser.parse(), options)
		js = compiler.compile()
		
		# Debug compiler
		console.error "\nCompiled Function:\n\n\u001b[90m%s\u001b[0m", js.replace(/^/g, "  ")  if options.debug
		return "" + "var buf = [];\n" + ((if options.self then "var self = locals || {};\n" + js else "with (locals || {}) {\n" + js + "\n}\n")) + "return buf.join(\"\");"
	catch err
		parser = parser.context()
		runtime.rethrow err, parser.filename, parser.lexer.lineno

###
Strip any UTF-8 BOM off of the start of `str`, if it exists.

@param {String} str
@return {String}
@api private
###
stripBOM = (str) ->
	(if 0xFEFF is str.charCodeAt(0) then str.substring(1) else str)

###
Compile a `Function` representation of the given jade `str`.

Options:

- `compileDebug` when `false` debugging code is stripped from the compiled template
- `client` when `true` the helper functions `escape()` etc will reference `jade.escape()`
for use with the Jade client-side runtime.js

@param {String} str
@param {Options} options
@return {Function}
@api public
###
exports.compile = (str, options) ->
	options = options or {}
	client = options.client
	filename = (if options.filename then JSON.stringify(options.filename) else "undefined")
	fn = undefined
	str = stripBOM(String(str))
	if options.compileDebug isnt false
		fn = ["var __jade = [{ lineno: 1, filename: " + filename + " }];", "try {", parse(str, options), "} catch (err) {", "  rethrow(err, __jade[0].filename, __jade[0].lineno);", "}"].join("\n")
	else
		fn = parse(str, options)
	fn = "attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;\n" + fn  if client
	fn = new Function("locals, attrs, escape, rethrow, merge", fn)
	return fn if client
	(locals) ->
		fn locals, runtime.attrs, runtime.escape, runtime.rethrow, runtime.merge


###
Render the given `str` of jade and invoke
the callback `fn(err, str)`.

Options:

- `cache` enable template caching
- `filename` filename required for `include` / `extends` and caching

@param {String} str
@param {Object|Function} options or fn
@param {Function} fn
@api public
###
exports.render = (str, options, fn) ->
	# swap args
	if "function" is typeof options
		fn = options
		options = {}
	
	# cache requires .filename
	return fn(new Error("the \"filename\" option is required for caching"))  if options.cache and not options.filename
	try
		path = options.filename
		tmpl = (if options.cache then exports.cache[path] or (exports.cache[path] = exports.compile(str, options)) else exports.compile(str, options))
		fn null, tmpl(options)
	catch err
		fn err


###
Render a Jade file at the given `path` and callback `fn(err, str)`.

@param {String} path
@param {Object|Function} options or callback
@param {Function} fn
@api public
###
exports.renderFile = (path, options, fn) ->
	key = path + ":string"
	if "function" is typeof options
		fn = options
		options = {}
	try
		options.filename = path
		str = (if options.cache then exports.cache[key] or (exports.cache[key] = fs.readFileSync(path, "utf8")) else fs.readFileSync(path, "utf8"))
		exports.render str, options, fn
	catch err
		fn err


#Express support
exports.__express = exports.renderFile
