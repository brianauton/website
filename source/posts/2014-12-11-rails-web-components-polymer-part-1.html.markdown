---
title: Rails and Web Components Part 1&#58; Adding Polymer to a Rails App
tags: rails, polymer
---

My horizons were expanded a little bit by Dane O'Connor's recent talk on [web components] and
[Polymer] at [Software As Craft Philadelphia]. Not knowing much about web components, I didn't
realize there was such an elegant way to encapsulate the related JavaScript, CSS, and HTML for
a single piece of a website's behavior without having to manipulate global state. That's a
huge improvement to the state of the art for front-end development, and I immediately wondered
how easy it would be to start including this stuff in some of my current Rails projects.

If you're not already familiar with the basic idea of web components and how they work from a
purely front-end perspective, take a look at the [introduction on the Polymer site]. Otherwise,
read on to learn about the mostly painless process I used to get web components up and running
in an existing Rails app.
READMORE

### Asset Pipeline Support

In pursuit of a simple solution, I considered bypassing the asset pipeline and dumping some
components into the public directory. But it turns out that a single gem addition can teach
the asset pipeline how to package up web components just like other assets. [The Emcee gem]
seems to be really good at this, so I started by adding `emcee` to my Gemfile and updating the
bundle. Next I ran Emcee's generator to create a few useful files:

```
rails g emcee:install
```

That gave me a brand new manifest file for web components, similar to the familiar
application.js and application.css manifests, except this one's an html file. Emcee also added
a reference to the new manifest file to my application layout. At this point I'm free to add
my own components to `app/assets/components`, and they'll get served up by the asset pipeline.

### Installing a Component

But before diving into custom components, I wanted to see a stock component working in my app
as a proof of concept. The Polymer project includes [lots of components], including a full set
that implement Google's [material design guidelines]. I could download a component along with
each of its dependencies from the Polymer site and unzip them all into
`app/assets/components`, but this process can easily be automated with a front-end package
manager like [Bower], which is Polymer's recommended way to install components.

I wasn't already using Bower to manage any of my Rails assets, but it's easy to install with
[node] and [npm]. Installing those isn't covered here, but they're widely supported and should
be easy to set up on any modern system that doesn't have them already. Since I already had
node and npm, installing bower was easy:

```
npm install -g bower
```

After that, any Polymer component and all its dependencies can be installed with a single
bower command. Emcee already created a .bowerrc file to tell Bower to put packages in
`vendor/assets/components`, where they'll be available to the asset pipeline but separate from
any custom components I might add to `app/assets/components`. I decided to install a stock
Polymer component that implements a material-styled button:

```
bower install Polymer/paper-button
```

I also added it to the manifest at `app/assets/components/application.html`.

```
*= require paper-button/paper-button
```

### Using the New Component

Now the installation is done, and I'm free to drop the component's custom HTML element (in
this case, `<paper-button>`) into any view in my app, and the component will show up on the
page. Or at least it will show up in Chrome (more on browser compatibility in a moment).

```
<paper-button raised>My Button Text</paper-button>
```

After adding this code to a view, I have a button with its own "paper" styling and fancy
JavaScript behavior, and all this complexity is fully encapsulated behind the `<paper-button>`
tag. The button has complex CSS styles that look very different from the rest of my app, but I
didn't have to change any of my existing CSS or selector names to avoid conflicts. The button
uses a web font that I didn't previously have in my project, but I didn't have to install that
either. And I don't know or care if the button depends on a hundred different JavaScript
libraries, because I didn't have to separately include them in my project. If you think this
sounds like a refreshingly modern way to manage front-end dependencies, you're starting to
understand why web components are a big deal.

### Supporting More Browsers

But at this point the component still didn't show up in any browser other than
Chrome. Luckily, Polymer provides a library of JavaScript workarounds that extend web
component support to browsers that haven't yet implemented all the necessary HTML features
natively.

The library is called [webcomponents.js], and Bower already installed it as one of
paper-button's dependencies. I first tried including this library by referencing it in
`app/assets/javascripts/application.js`. But this broke the [Poltergeist-driven] acceptance
tests in my test suite, because PhantomJS doesn't get along well with webcomponents.js. So as
a temporary fix to keep my test suite passing, I had to include webcomponents.js in a way that
let me turn it off in test mode. I ended up adding a separate include tag to my application
layout:

```
<%= javascript_include_tag "webcomponentsjs/webcomponents" unless Rails.env.test? %>
```

And then I needed to add it as an asset to be separately precompiled. This went in
`config/initializers/assets.rb` with the rest of my asset pipeline configuration.

```
Rails.application.config.assets.precompile << "webcomponentsjs/webcomponents.js"
```

After that, my paper-button looked perfect in Firefox and Mobile Safari as well.

### Testing Issues and Future Topics

It's a problem that web components don't yet work well with PhantomJS (and probably other
similar testing tools), because I will definitely need acceptance-level testing of web
components once my app starts to really depend on them. And once I start creating custom
components of any real complexity, I'll also need to unit test them, which is something the
Polymer team is [actively working on]. I'll revisit these testing issues in a future post.

Also in a future post, I'll look into the best ways for web components to interact with data
that lives on the server side of a Rails app. But for now, if you've been following along,
you're ready to further explore the components described in the Polymer docs, as well as their
tutorials on how to make your own custom components. Until next time, enjoy your trip into the
future of web development.

[web components]: http://webcomponents.org/
[Polymer]: https://www.polymer-project.org/
[Software as Craft Philadelphia]: http://www.meetup.com/Software-as-Craft-Philadelphia/
[introduction on the Polymer site]: https://www.polymer-project.org/docs/start/everything.html
[The Emcee gem]: https://github.com/ahuth/emcee
[lots of components]: https://www.polymer-project.org/docs/start/usingelements.html
[material design guidelines]: http://www.google.com/design/spec/material-design/introduction.html#
[Bower]: http://bower.io/
[node]: http://nodejs.org/
[npm]: http://npmjs.org/
[webcomponents.js]: http://webcomponents.org/polyfills/
[Poltergeist-driven]: https://github.com/teampoltergeist/poltergeist
[actively working on]: https://github.com/Polymer/web-component-tester
