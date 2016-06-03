# Contributing to Onyx

**You've decided to be part of changing the future of programming! Awesome!**

## Some things we currently need to focus on ##

<<<<<<< HEAD
* Settling the syntax.
* Settling cornerstone library (standard library) API names.
* Implementing syntax.
* Finding bugs.
* Fixing bugs.
* Highlighters - currently Sublime highlighter exists.
* Documenting the language.
* Making good examples, and "Onyx for C++-coders", "Onyx for Pythoners", "Onyx for Rubyists" etc. guides.
=======
You can find a list of tasks that we consider suitable for a first time contribution at
the [newcomer label](https://github.com/crystal-lang/crystal/labels/newcomer).

Furthermore these are the most important general things in need right now:
>>>>>>> foreign/master

## Use GitHub issue tracker! ##

Use the issue tracker for bugs, questions, proposals and feature requests.
If you open a question, try to remember to close the issue once you are satisfied with the answer and you think there's no more room for discussion. We'll close issues after some time of considering it as done otherwise.

## Guidelines for issues / RFCs ##
- When thinking up a syntax construct, first think of what constructs it
  might clash with / create ambiguity, if realized - rethink!
- Can it already be solved by using macros/templates, if so is it really
  needed as first class member of the language?
- There's no need nor point to "fight" for your idea - see if an even
  greater idea synthesizes from the discussions around your idea and aim to
  find the best arguments and possible proof to validate it. _Expect_ greater
  things to happen than your original idea. That's collaboration.
- Motivate the idea! Please motivate the construct. Use-cases etc.
- Prior art. When applicable, refer to inspiration sources, prior art of
  the construct or models of similar nature.

## RFC "template" example ##

```text
I propose this and that. Bla blabla.

\`\`\`onyx
   some-syntax-example-here == great
   so(its_easily_understood)
\`\`\`

## Motivation ##
This would be beneficial for this and that. It won't interfere with this
or that. It will be super much faster. Or whatever stuff.

## Prior Art ##
This and that language has this construct [...example], which seem to
have worked well in practice. Bla bla. By the proposed syntax, it merges
fine with the rest of Onyx, bla bla.
```

Ok - you catch the drift - right?

## Formatting specifics ##

- MarkDown docs
    - use soft word-wrapping, and let paragraphs be one long line in literal. - Use `_italics_` and `**bold**` consistently if you remember (you won't get shot).
    - `# Headline #` for headlines - _not_ underlining. Complementary suffix hashes looks nice, try that.
    - This way we get less merge noise.
- Crystal code - to facilitate sharing with the crystal project (an objective), follow crystal projects style (simply use the formatter!).

The source code follows the same style guide lines as Crystal (just use the formatter!) for the time being - since it simplifies features making its way back into the Crystal repo when reasonable.

## Contribute to THIS guide ##

If this is too vague currently - just PR changes!

## Onyx Project Code of Conduct ##

Whatever you think promotes and helps the language forward is enough for code of conduct for now. If someone is offended - you've probably been an asshole;  acknowledge it and apologize. We can all stumble down that road some times. Apologizing is a strong and proud act.

Cursing is ~~fucking~~ allowed, but not necessarily decreed.

If someone starts acting in a way that reduces others' happiness or
productivity _chronically_, then we might revise this.

Everyone with an interest is welcome, no matter where you come from linguistically or otherwise (creed, religion, sexual orientation, sexual make-up or _even_ musical taste). In fact different backgrounds are essential for a good project.

## Gitting Down to Business ##

1. Fork it ( https://github.com/ozra/onyx-lang/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

**Do some sausage making before commit** - we want one commit: "Add this-and-that-feature", _not_: ~~"changed x", "fix y", "forgot trailing spaces", "this-and-that-feature done"~~ (note especially to @ozra ;-) )
