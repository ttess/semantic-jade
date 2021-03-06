
# Semantic Jade

The semantic-jade template engine for node.js

## Synopsis

	jade [-h|--help] [-v|--version] [-o|--obj STR]
	     [-O|--out DIR] [-p|--path PATH] [-P|--pretty]
	     [-c|--client] [-D|--no-debug]

## Examples

translate jade the templates dir

	$ jade templates

create {foo,bar}.html

	$ jade {foo,bar}.jade

jade over stdio

	$ jade < my.jade > my.html

jade over s

	$ echo "h1 Jade!" | jade

foo, bar dirs rendering to /tmp

	$ jade foo bar --out /tmp

compile client-side templates without debugging
instrumentation, making the output javascript
very light-weight. This requires runtime.js
in your projects.

	 $ jade --client --no-debug < my.jade

## Tags

Tags are simply nested via whitespace, closing
tags defined for you. These indents are called "blocks".

```jade
ul
	li
		a Foo
	li
		a Bar
```

You may have several tags in one "block":

```jade
ul
	li
		a Foo
		a Bar
		a Baz
```

## Self-closing Tags

Some tags are flagged as self-closing by default, such
as `meta`, `link`, and so on. To explicitly self-close
a tag simply append the `/` character:

```jade
foo/
foo(bar='baz')/
```

Would yield:

```html
<foo/>
<foo bar="baz"/>
```

## Attributes

Tag attributes look similar to HTML, however
the values are regular JavaScript, here are
some examples:

```jade
a(href='google.com') Google
a(class='button', href='google.com') Google
```

As mentioned the attribute values are just JavaScript,
this means ternary operations and other JavaScript expressions
work just fine:

```jade
body(class=user.authenticated ? 'authenticated' : 'anonymous')
a(href=user.website || 'http://google.com')
```

Multiple lines work too:

```jade
input(type='checkbox',
	name='agreement',
	checked)
```

Multiple lines without the comma work fine:

```jade
input(type='checkbox'
	name='agreement'
	checked)
```

Funky whitespace? fine:

```jade
input(
	type='checkbox'
	name='agreement'
	checked)
```

## Boolean attributes

Boolean attributes are mirrored by Jade, and accept
bools, aka _true_ or _false_. When no value is specified
_true_ is assumed. For example:

```jade
input(type="checkbox", checked)
// => "<input type="checkbox" checked="checked" />"
```

For example if the checkbox was for an agreement, perhaps `user.agreed`
was _true_ the following would also output 'checked="checked"':

```jade
input(type="checkbox", checked=user.agreed)
```

## Class attributes

The _class_ attribute accepts an array of classes,
this can be handy when generated from a javascript
function etc:

```jade
classes = ['foo', 'bar', 'baz']
a(class=classes)
// => "<a class="foo bar baz"></a>"
```

## Class literal

Classes may be defined using a ".CLASSNAME" syntax:
```jade
.button
// => "<div class="button"></div>"
```

Or chained:

```jade
.large.button
// => "<div class="large button"></div>"
```

The previous defaulted to divs, however you
may also specify the tag type:

```jade
h1.title My Title
// => "<h1 class="title">My Title</h1>"
```

## Id literal

Much like the class literal there's an id literal:

```jade
#user-1
// => "<div id="user-1"></div>"
```

Again we may specify the tag as well:

```jade
ul#menu
	li: a(href='/home') Home
	li: a(href='/store') Store
	li: a(href='/contact') Contact
```

Finally all of these may be used in any combination,
the following are all valid tags:

```jade
a.button#contact(style: 'color: red') Contact
a.button(style: 'color: red')#contact Contact
a(style: 'color: red').button#contact Contact
```

## Block expansion

Jade supports the concept of "block expansion", in which
using a trailing ":" after a tag will inject a block:

```jade
ul
	li: a Foo
	li: a Bar
	li: a Baz
```

## Text

 Arbitrary text may follow tags:

```jade
p Welcome to my site
```

yields:

```html
<p>Welcome to my site</p>
```

## Pipe text

Another form of text is "pipe" text. Pipes act
as the text margin for large bodies of text.

```jade
p
	| This is a large
	| body of text for
	| this tag.
	| 
	| Nothing too
	| exciting.
```

yields:

```html
<p>This is a large
body of text for
this tag.

Nothing too
exciting.
</p>
```

Using pipes we can also specify regular Jade tags
within the text:

```jade
p
	| Click to visit
	a(href='http://google.com') Google
	| if you want.
```

## Text only tags

As an alternative to pipe text you may add
a trailing "." to indicate that the block
contains nothing but plain-text, no tags:

```jade
p.
	This is a large
	body of text for
	this tag.

	Nothing too
	exciting.
```

This is especially useful for tags like:

```jade
script.
	if (foo) {
		bar();
	}
```

and

```jade
style.
	body {
		padding: 50px;
		font: 14px Helvetica;
	}
```

## Template script tags

Sometimes it's useful to define HTML in script
tags using Jade, typically for client-side templates.

To do this simply give the _script_ tag an arbitrary
_type_ attribute such as _text/x-template_:

```jade
script(type='text/template')
	h1 Look!
	p Jade still works in here!
```

## Interpolation

Both plain-text and piped-text support interpolation,
which comes in two forms, escapes and non-escaped. The
following will output the _user.name_ in the paragraph
but HTML within it will be escaped to prevent XSS attacks:

```jade
p Welcome #{user.name}
```

The following syntax is identical however it will _not_ escape
HTML, and should only be used with strings that you trust:

```jade
p Welcome !{user.name}
```

## Inline HTML

Sometimes constructing small inline snippets of HTML
in Jade can be annoying, luckily we can add plain
HTML as well:

```jade
p Welcome <em>#{user.name}</em>
```

## Code

To buffer output with Jade simply use _=_ at the beginning
of a line or after a tag. This method escapes any HTML
present in the string.

```jade
p= user.description
```

To buffer output unescaped use the _!=_ variant, but again
be careful of XSS.

```jade
p!= user.description
```

The final way to mess with JavaScript code in Jade is the unbuffered
_-_, which can be used for conditionals, defining variables etc:

```jade
- var user = { description: 'foo bar baz' }
#user
	- if (user.description) {
		h2 Description
		p.description= user.description
	- }
```

 When compiled blocks are wrapped in anonymous functions, so the
 following is also valid, without braces:

```jade
- var user = { description: 'foo bar baz' }
#user
	- if (user.description)
		h2 Description
		p.description= user.description
```

 If you really want you could even use `.forEach()` and others:

```jade
- users.forEach(function(user){
	.user
		h2= user.name
		p User #{user.name} is #{user.age} years old
- })
```

Taking this further Jade provides some syntax for conditionals,
iteration, switch statements etc. Let's look at those next!

## Mixins

Mixins provide a way to define jade "functions" which "mix in"
their contents when called. This is useful for abstracting
out large fragments of Jade.

The simplest possible mixin which accepts no arguments might
look like this:

```jade
mixin hello
	p Hello
```

 You use a mixin by placing `+` before the name:

```jade
+hello
```

 For something a little more dynamic, mixins can take
 arguments, the mixin itself is converted to a javascript
 function internally:

```jade
mixin hello(user)
	p Hello #{user}
```

```jade
+hello('Tobi')
```

Yields:

```html
<p>Hello Tobi</p>
```

Mixins may optionally take blocks, when a block is passed
its contents becomes the implicit `block` argument. For
example here is a mixin passed a block, and also invoked
without passing a block:

```jade
mixin article(title)
	.article
		.article-wrapper
			h1= title
			if block
				block
			else
				p No content provided

+article('Hello world')

+article('Hello world')
	p This is my
	p Amazing article
```

 yields:

```html
<div class="article">
	<div class="article-wrapper">
		<h1>Hello world</h1>
		<p>No content provided</p>
	</div>
</div>

<div class="article">
	<div class="article-wrapper">
		<h1>Hello world</h1>
		<p>This is my</p>
		<p>Amazing article</p>
	</div>
</div>
```

Mixins can even take attributes, just like a tag. When
attributes are passed they become the implicit `attributes`
argument. Individual attributes can be accessed just like
normal object properties:

mixin centered
	.centered(class=attributes.class)
		block

+centered.bold Hello world

+centered.red
	p This is my
	p Amazing article

yields:

```html
<div class="centered bold">Hello world</div>
<div class="centered red">
	<p>This is my</p>
	<p>Amazing article</p>
</div>
```

 If you use `attributes` directly, *all* passed attributes
 get used:

```jade
mixin link
	a.menu(attributes)
		block

+link.highlight(href='#top') Top
+link#sec1.plain(href='#section1') Section 1
+link#sec2.plain(href='#section2') Section 2
```

 yields:

```html
<a href="#top" class="highlight menu">Top</a>
<a id="sec1" href="#section1" class="plain menu">Section 1</a>
<a id="sec2" href="#section2" class="plain menu">Section 2</a>
```

 If you pass arguments, they must directly follow the mixin:
 
mixin list(arr)
	if block
		.title
			block
	ul(attributes)
		each item in arr
			li= item

+list(['foo', 'bar', 'baz'])(id='myList', class='bold')

yields:

```html
<ul id="myList" class="bold">
	<li>foo</li>
	<li>bar</li>
	<li>baz</li>
</ul>
```
