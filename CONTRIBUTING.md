# Contributing to Diagnostics

As the creators, and maintainers of this project, we're glad to share our projects and invite contributors to help us stay up to date. Please take a moment to review this document in order to make the contribution process easy and effective for everyone involved.

Following these guidelines helps to communicate that you respect the time of the developers managing and developing this open source project. In return, they should reciprocate that respect in addressing your issue or assessing patches and features.

## Using the issue tracker for bug reports, feature requests and discussions

### First time contributors
We should encourage first time contributors. A good inspiration on this can be found [here](http://www.firsttimersonly.com/). As pointed out:

> If you are an OSS project owner, then consider marking a few open issues with the label first-timers-only. The first-timers-only label explicitly announces:

> "I'm willing to hold your hand so you can make your first PR. This issue is rather a bit easier than normal. And anyone who’s already contributed to open source isn’t allowed to touch this one!"

By labeling issues with this `first-timers-only` label we help first time contributors step up their game and start contributing.

### Bug reports

A bug is a _demonstrable problem_ that is caused by the code in the repository.
Good bug reports are extremely helpful - thank you!

Guidelines for bug reports:

1. **Use the GitHub issue search** &mdash; check if the issue has already been
   reported.

2. **Check if the issue has been fixed** &mdash; try to reproduce it using the
   latest `main` or development branch in the repository.

3. **Isolate the problem** &mdash; provide clear steps to reproduce.

A good bug report shouldn't leave others needing to chase you up for more
information. Please try to be as detailed as possible in your report. What is
your environment? What steps will reproduce the issue? What would you expect to be the outcome? All these details will help people to fix any potential bugs.

Example:

> Short and descriptive example bug report title
>
> A summary of the issue and the OS environment in which it occurs. If
> suitable, include the steps required to reproduce the bug.
>
> 1. This is the first step
> 2. This is the second step
> 3. Further steps, etc.
>
> `<url>` - a link to the reduced test case, if possible
>
> Any other information you want to share that is relevant to the issue being
> reported. This might include the lines of code that you have identified as
> causing the bug, and potential solutions (and your opinions on their
> merits).

### Feature requests

Feature requests are welcome. But take a moment to find out whether your idea
fits with the scope and aims of the project. It's up to *you* to make a strong
case to convince the project's developers of the merits of this feature. Please
provide as much detail and context as possible.

Do check if the feature request already exists. If it does, give it a thumbs-up emoji
or even comment. We'd like to avoid duplicate requests.

### Pull requests

Good pull requests - patches, improvements, new features - are a fantastic
help. They should remain focused in scope and avoid containing unrelated
commits.

**Please ask first** before embarking on any significant pull request (e.g.
implementing features, refactoring code, porting to a different language),
otherwise you risk spending a lot of time working on something that the
project's developers might not want to merge into the project. As far as _where_ to ask,
the feature request or bug report is the best place to go.

Please adhere to the coding conventions used throughout a project (indentation,
accurate comments, etc.) and any other requirements (such as test coverage).

Follow this process if you'd like your work considered for inclusion in the
project:

1. [Fork](http://help.github.com/fork-a-repo/) the project, clone your fork,
   and configure the remotes:

   ```bash
   # Clone your fork of the repo into the current directory
   git clone git@github.com:AvdLee/Diagnostics.git
   # Navigate to the newly cloned directory
   cd Diagnostics
   # Assign the original repo to a remote called "upstream"
   git remote add upstream git@github.com:AvdLee/Diagnostics.git
   ```

2. If you cloned a while ago, get the latest changes from upstream:

   ```bash
   git checkout <dev-branch>
   git pull upstream <dev-branch>
   ```

3. Create a new topic branch (off the main project development branch) to
   contain your feature, change, or fix:

   ```bash
   git checkout -b <topic-branch-name>
   ```

4. Commit your changes in logical chunks.

5. Locally merge (or rebase) the upstream development branch into your topic branch:

   ```bash
   git pull [--rebase] upstream <dev-branch>
   ```

6. Push your topic branch up to your fork:

   ```bash
   git push origin <topic-branch-name>
   ```

7. [Open a Pull Request](https://help.github.com/articles/using-pull-requests/)
    with a clear title and description.

### Conventions of commit messages

Adding features on repo

```bash
git commit -m "feat: message about this feature"
```

Fixing features on repo

```bash
git commit -m "fix: message about this update"
```

Removing features on repo

```bash
git commit -m "refactor: message about this" -m "BREAKING CHANGE: message about the breaking change"
```


**IMPORTANT**: By submitting a patch, you agree to allow the project owner to
license your work under the same license as that used by the project.

### Discussions

We aim to keep all project discussion inside GitHub issues. This is to make sure valuable discussion is accessible via search. If you have questions about how to use the library, or how the project is running - GitHub issues are the goto tool for this project.

#### Our expectations on you as a contributor

We want contributors to provide ideas, keep the ship shipping and to take some of the load from others. It is non-obligatory; we’re here to get things done in an enjoyable way. 🎉

The fact that you'll have push access will allow you to:

- Avoid having to fork the project if you want to submit other pull requests as you'll be able to create branches directly on the project.
- Help triage issues, merge pull requests.
- Pick up the project if other maintainers move their focus elsewhere.
