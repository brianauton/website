---
title: The Best Commit Messages Are Just One Line
tags: git
---

If you want a simple way to make your commit messages more effective, try strictly limiting
them to one line. Many developers and teams try to be helpful by packing extra detail into the
body of each commit message whenever possible. But this detail takes extra time to write and
to read, and it rarely adds any value. Here are some things I've often seen wasting space in
the body of a multi-line commit message.

READMORE

__Specific descriptions of changes to the code.__ Anyone who wants more detail about your
commit after seeing it as a one-liner in the commit history will end up looking at the
individual file changes in addition to the commit message. So in a commit whose main purpose
was to “add a User model”, they'll know that you also “added a mirgration” and “added a unit
test.”  There's no need to list those redundant details in the commit message. And there's
always the chance that you'll make a mistake or leave something out, and the resulting
misleading message is worse than no message at all.

__Notes about follow-on tasks or things that still need to be done.__ _“Still need to add
acceptance tests”._ _“This should be factored out into a new class”._ If those tasks are
required to finish the current feature, just do them as subsequent commits before you call the
feature done. If they're vital tasks but not part of the current feature, add them to the
project's issue tracking software. After all, no one is combing commit messages for stuff to
do, so you can't leave the completion of a vital feature up to the chance that someone will
notice the reminder in your commit message. If they're not vital, save everyone's time by
leaving them out.

__Full URL to the issue tracker software.__ I like commit messages that start with a brief
reference to the issue number itself, mainly because that's a great way to visually group
related commits together. But it becomes tedious to paste a full URL into the commit message
body once you realize that no one has a good reason to follow it. Developers working on the
issue will already have it close at hand. Stakeholders verifying that a feature is complete or
a bug is fixed are looking at the application behavior, not at the commit history. And no one
looking back to your code in the future needs to be distracted by discussions of external
requirements that are now outdated, or alternate approaches that were ultimately abandoned.

__Discussion of requirements for the feature.__ _“Designer asked for a darker navbar, so we're
trying #000066.”_ This is like linking to the issue, but worse, because it pulls irrelevant
discussion out of the issue tracker and directly into the codebase. The commit message should
focus on what was actually done to the code, not what should have been done.

__Long descriptions.__ Eliminating all the offenders above leaves what's really important: the
high-level description of what you changed. If this is too long to fit in one line, the
problem may be that your commit is too big. Multiple sentences (as well as multiple clauses
separated by “and”) usually signify separate concerns that should have been committed
separately. If you've squashed an entire feature branch into a single commit before merging,
stop doing that. Let your commit messages tell a story about how you solved the problem in
individual steps.

Use appropriate commit sizes and practice revising your wording and eliminating the dead
weight. You can get almost any commit message down to just one line, and each one will add
highly-focused value to the project and make the best use of everyone's time.
