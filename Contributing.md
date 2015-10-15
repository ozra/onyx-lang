# Contributing to Onyx

You've decided to be part of changing the future of programming! Awesome!

## Some things we currently need to focus on ##

* Settling the syntax.
* Settlings standard library API names.
* Implementing syntax.
* Finding bugs.
* Fixing bugs.
* Highlighters - currently Sublime/Textmate compatible exists.
* Documenting the language.
* Making good examples, and "Onyx for C++-coders", "Onyx for pythoners", etc. guides.


## Use GitHub issue tracker!

Use the issue tracker for bugs, questions, proposals and feature requests.
The issue tracker is very convenient for all of this because of its ability to link to a particular commit
or another issue, include code snippets, etc.
If you open a question, remember to close the issue once you are satisfied with the answer and you think
there's no more room for discussion. We'll close issues after some time of seeing it as done otherwise.

## Guidelines for issues / RFCs ##
- When thinking up a syntax construct, first think of what constructs it
  might clash with / create ambiguity, if realized - rethink!
- Can it already be solved by using macros/templates, if so is it really
  needed as first class member of the language?
- There's no need nor point to "fight" for your idea - see if an even
  greater idea synthesizes from the discussions around your idea and aim to
  find the best arguments and possible proof to validate it. _Expect_ greater
  things to happen than your original idea. That's collaboration.
- Motivate the idea! Please motivate the construct. Use cases etc.
- Prior art. When applicable, refer to inspiration sources, prior art of
  the construct or similar models.

## RFC "template" example ##

```
I propose this and that. Bla blabla.

\`\`\`onyx
   some-syntax-example-here == great
   so(its_easily_understood)
\`\`\`

## Motivation
This would be beneficial for this and that. It won't interfere with this
or that. It will be super much faster. Or whatever stuff.

## Prior Art ##
This and that language has this construct [...example], which seem to
have worked well in practise. Bla bla. By the proposed syntax, it merges
fine with the rest of Onyx, bla bla.
```

Ok - you catch the drift - right?

## Contribute to THIS guide ##

If this is to vague currently - just PR changes!

## Code of Conduct ##

What ever you think promotes and helps the language forward is enough
for code of conduct for now. If someone is offended - you've probably
been an asshole, then apologize. We can all stumble down that road some
time.
If someone starts acting in a way that reduces others happiness or
productivity, _then_ we might revise this.

