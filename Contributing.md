# Contributing to Onyx

**You've decided to be part of changing the future of programming! Awesome!**

## Some things we currently need to focus on ##

* Settling the syntax.
* Settling cornerstone library (standard library) API names.
* Implementing syntax, that isn't already (changes).
* Finding bugs.
* Fixing bugs.
* Highlighters - currently Sublime and Atom highlighter exists.
* Documenting the language.
* Making good examples, and "Onyx for C++-coders", "Onyx for Pythoners", "Onyx for Rubyists" etc. guides.

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
=======
* Documenting the language
* Documenting the standard library
* Adding missing bits of the standard library, and/or improving its performance

## Contributing to the documentation

The main website is at [crystal-lang/crystal-website](https://github.com/crystal-lang/crystal-website),
please have a look over there if you want to contribute to it.

We use [GitBook](https://www.gitbook.com/) for the [language documentation](https://crystal-lang.org/docs/).
See the repository at [crystal-lang/crystal-book](https://github.com/crystal-lang/crystal-book) for how to contribute to it.

The [standard library documentation](https://crystal-lang.org/api/) is on the code itself, in this repository.
There is a version updated with every push to the master branch [here](https://crystal-lang.org/api/master/).
It uses a subset of [Markdown](http://daringfireball.net/projects/markdown/). You can [use Ruby as a source
of inspiration](https://twitter.com/yukihiro_matz/status/549317901002342400) whenever applicable. To generate
the docs execute `make doc`. Please follow the guidelines described in our
[language documentation](https://crystal-lang.org/docs/conventions/documenting_code.html), like the use of the third person.

## Contributing to the standard library

1. Fork it ( https://github.com/crystal-lang/crystal/fork )
2. Clone it

Be sure to execute `make libcrystal` inside the cloned repository.

Once in the cloned directory, and once you [installed Crystal](http://crystal-lang.org/docs/installation/index.html),
you can execute `bin/crystal` instead of `crystal`. This is a wrapper that will use the cloned repository
as the standard library. Otherwise the barebones `crystal` executable uses the standard library that comes in
your installation.

Next, make changes to the standard library, making sure you also provide corresponding specs. To run
the specs for the standard library, run `bin/crystal spec/std_spec.cr`. To run a particular spec: `bin/crystal spec/std/array_spec.cr`.

Note: at this point you might get long compile error that include "library not found for: ...". This means
you are [missing some libraries](https://github.com/crystal-lang/crystal/wiki/All-required-libraries).

Make sure that your changes follow the recommended [Coding Style](https://crystal-lang.org/docs/conventions/coding_style.html).
You can run `crystal tool format` to automate this.

Then push your changes and create a pull request.

## Contributing to the compiler itself

If you want to add/change something in the compiler,
the first thing you will need to do is to [install the compiler](https://crystal-lang.org/docs/installation/index.html).

Once you have a compiler up and running, and that executing `crystal` on the command line prints its usage,
it's time to setup your environment to compile Crystal itself, which is written in Crystal. Check out
the `install` and `before_install` sections found in [.travis.yml](https://github.com/crystal-lang/crystal/blob/master/.travis.yml).
These set-up LLVM 3.6 and its required libraries.

Next, executing `make clean crystal spec` should compile a compiler and using that compiler compile and execute
the specs. All specs should pass.

## Maintain clean pull requests

The commit history should consist of commits that transform the codebase from one state into another one, motivated by something that
should change, be it a bugfix, a new feature or some ground work to support a new feature, like changing an existing API or introducing
a new isolated class that is later used in the same pull request. It should not show development history ("Start work on X",
"More work on X", "Finish X") nor review history ("Fix comment A", "Fix comment B"). Review fixes should be squashed into the commits
that introduced them. If your change fits well into a single commit, simply keep editing it with `git commit --amend`. Partial staging and
committing with `git add -p` and `git commit -p` respectively are also very useful. Another good tool is `git stash` to put changes aside while
switching to another commit. But Git's most useful tool towards this goal is the interactive rebase.

### Doing an interactive rebase

First let's make sure we have a clean reference to rebase upon:

```sh
git remote add upstream https://github.com/crystal-lang/crystal.git
>>>>>>> foreign/master
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
