---
title: Rails Token Authentication Without Devise
tags: rails
---

> A popular solution for token-based authentication in Rails has been
retired, and the most common replacements leave some security issues
unaddressed.  Here's a solution with a clean and maintainable design.

Anyone working on a modern Rails application is probably familiar with
[Devise]. It's by far the [most popular] drop-in solution for handling
authentication of the username and password variety. Anyone who also
needs to offer token-based authentication (maybe in order to offer a
REST API), might be accustomed to using Devise for this too, through
its handy `token_authenticatable` feature.

Those developers might be dismayed, as I was, to find that
`token_authenticatable` has been [removed] from recent versions of
Devise. They might be further dismayed to find that the only solution
that has any sort of consensus as a replacement seems dubious for a
couple of different reasons.

[Devise]: https://github.com/plataformatec/devise
[most popular]: https://www.ruby-toolbox.com/categories/rails_authentication
[removed]: https://github.com/plataformatec/devise/issues/2616

READMORE

#### The Problem and Solutions So Far

Why was `token_authenticatable` removed? According to the [official
blog post], the concern was raised that authentication tokens (along
with other non-password secrets like password reset tokens) have
traditionally been stored in plain text by Devise, and as such are
vulnerable to timing attacks. This is true, and they are also
vulnerable to brute-force cracking attempts, as well as being
completely exposed in the event of unauthorized read access to the
database.

Of course, all these issues have been long known as they pertain to
the traditional user passwords that are at the core of Devise's
functionality. That's why Devise has always run these passwords
through a [password hash function] before storing them in the
database. A good password hash function, such as the widely-trusted
[bcrypt] that Devise uses by default, solves all these problems at
once, and there's very little reason not to use one when handling any
data that is used as a password.

As of version 3.1, Devise began protecting most of its non-password
secrets by hashing them with bcrypt as well. But hashing an
authentication token that's intended for repeated use presents a
couple of extra challenges. For one, if bcrypt authentication needs to
be performed on every request to an API, the extra performance penalty
could result in a significant slowdown. Also, the user experience
around API-enabled websites is often designed so that a user can
retreive their API token if they've forgotten it, which is impossible
if the token is only stored as a hash.

The Devise team decided not to impose a single solution to these
problems on everyone who uses Devise for token
authentication. Instead, they removed the feature and linked to a
[gist] that presents two different code samples as starting points for
a custom solution to the problem. One of these is equivalent to
Devise's old behavior, and the other one adds some protection against
timing attacks at the expense of changing the application API and
requiring additional info from the users who are authenticating via
token.

On the plus side, this approach encourages users to think through the
solution as it applies to their individual applications, rather than
blindly copying code. On the other hand, it still amounts to the
strongly discouraged practice of [rolling one's own] security
code. Furthermore, the provided "secure" option only addresses the
timing attack problem, while continuing to store authentication
secrets in plain text and thus remaining exposed to the other
vulnerabilities.

[official blog post]: http://blog.plataformatec.com.br/2013/08/devise-3-1-now-with-more-secure-defaults/
[password hash function]: http://throwingfire.com/storing-passwords-securely/#notpasswordhashes
[bcrypt]: https://github.com/codahale/bcrypt-ruby
[gist]: https://gist.github.com/josevalim/fb706b1e933ef01e4fb6
[rolling one's own]: http://security.stackexchange.com/a/18198

#### An Alternate Solution

When facing these issues recently on a new API-focused application, I
found some opportunities to improve on the solution suggested by the
Devise team. Most importantly, I thought it was worth finding a way
around the performance and token-recoverability issues mentioned
above, to gain the benefit of using bcrypt to hash authentication
tokens. In addition to protecting against more vulnerabilities than
just timing attacks, this also means that while the overall security
architecture is hand-rolled, the most critical hashing and comparison
code is handed off to a trusted library.

In addition, I ended up with a solution that has a more modular and
maintainable design for the data model, and that's easily adaptable to
applications not using Devise. Let's walk through the solution below;
feel free to make use of it and make suggestions for further
improvement.

#### Storing the Secret

It's common practice to add additional authentication-related fields
to the application's User model, but let's defy that trend and create
a separate AuthenticationToken model. This will avoid conflicting with
any fields already on User, but more importantly, it decouples the
User model from the token authentication logic. This is very good for
maintainability, because changes to the authentication scheme won't
require changes to the User model (or models, as the case may be).

It's also good because it's flexible enough to allow multiple
AuthenticationTokens for each User. Later we'll discuss one reason why
we might want that. But for now, it means that we can't rely on a
User-specific piece of data (such as email address, as in the Devise
example) to uniquely identify the token value (which we'll call the
`secret`) that we hashed with bcrypt. So we'll need some kind of
searchable unique token identifier stored in plain text, and we'll
call that the `secret_id`. AWS users are used to keeping track of both
a "key id" and a "secret key" for exactly this reason.

As long as we're aiming for a modular design, we should also make the
user-to-token relationship polymorphic, so we'll only need one token
model in applications that have multiple user models (to which we'll
give the general label `authenticatable`). With all that in mind,
here's the migration for the token model:

```ruby
class CreateAuthenticationTokens < ActiveRecord::Migration
  def change
    create_table :authentication_tokens do |t|
      t.references :authenticatable, polymorphic: true
      t.string :secret_id
      t.string :hashed_secret
      t.timestamps
    end
    add_index :authentication_tokens, :secret_id, unique: true
  end
end
```

#### The Model

The `secret_id` and `hashed_secret` go in the database, while the
plaintext `secret` is only stored in memory. We need code in our
AuthenticationToken model to generate all three of these values, and
also code to perform the actual authentication by finding a token that
matches the `secret` and `secret_id` from a user request.

We'll make the
AuthenticationToken generate all three of these values before
validation any time they don't exist, which ensures that they'll exist
on newly-created tokens after saving. Here's the code for our
AuthenticationToken model:

```ruby
require "securerandom"
require "bcrypt"

class AuthenticationToken < ActiveRecord::Base
  belongs_to :authenticatable, polymorphic: true
  validates :secret_id, presence: true, uniqueness: true
  validates :hashed_secret, presence: true
  before_validation :generate_secret_id, unless: :secret_id
  before_validation :generate_secret, unless: :secret
  attr_accessor :secret

  def self.find_authenticated credentials
    token = where(secret_id: credentials[:secret_id]).first
    token if token && token.has_secret?(credentials[:secret])
  end

  def has_secret? secret
    BCrypt::Password.new(hashed_secret) == secret
  end

  private

  def generate_secret_id
    begin
      self.secret_id = SecureRandom.hex 8
    end while self.class.exists?(secret_id: self.secret_id)
  end

  def generate_secret
    self.secret = SecureRandom.urlsafe_base64 32
    self.hashed_secret = BCrypt::Password.create secret, cost: cost
  end

  def cost
    Rails.env.test? ? 1 : 10
  end
end
```

To authenticate, we'll just search for a token matching the given
`secret_id`, and then ask bcrypt to compare its `hashed_secret` against
the secret provided by the user. The result will be the matching
AuthenticationToken object, or nil if there's no match. Next, we just
need a couple of private methods to generate the secret and secret_id.

We also have code to generate the all the necessary secret-related
values at validation time. This ensures that when we save a
newly-created AuthenticationToken, it will have all the necessary
values (the plaintext secret will only be in memory, while the
secret_id and hashed_secret will get saved to the database).  We can
use Ruby's handy SecureRandom to generate both the secret and the
secret_id, and we'll give the secret considerably more entropy to make
sure it's secure. We also insert a little extra-paranoid protection
when generating the secret_id, to make sure it's unique.

Why does the secret_id need any entropy at all? In fact, why not just
use AuthenticationToken's existing `id` field? Because although it
suits our purposes by being unique, it also gives away information
about the chronological sequence of token creation and the total
number of tokens in our database. This information may or may not be
useful to potential attackers, but in general it's not the business of
anyone who hasn't authenticated.

Finally, we confront the API performance issue by carefully choosing
the `cost` value to pass in to bcrypt. In test mode, we want to use
the smallest value possible so our automated tests can generate and
authenticate tokens quickly. In production we're starting with the
same default of 10 that Devise uses, but we're free to turn it up for
extra security, or down for faster performance. If we turn it down all
the way to 1 for a negligible performance overhead in production,
we'll still have hashed secrets that are much more secure than plain
text.

#### The Controller

It's common with or without Devise to have a `current_user` method in
the controller to represent the logged-in user. We'll follow that
convention and add a `current_token` method that holds an
AuthenticationToken, if any is currently authenticated. Then the
controller can check for a `current_token` on each request, and
automatically log in any associated user. Here's the code to be added
to ApplicationController:

```ruby
class ApplicationController < ActionController::Base
  before_filter :authenticate_from_token

  protected

  def authenticate_from_token
    if current_token.try :authenticatable
      sign_in token.authenticatable, store: false
    end
  end

  def current_token
    AuthenticationToken.find_authenticated({
      secret: (params[:secret] || request.headers[:secret]),
      secret_id: (params[:secret_id] || request.headers[:secret_id]),
    })
  end
end
```

The `current_token` method includes the logic to find the credentials
being submitted by the user. Here, it's set up to recognize
credentials in either the params or the request headers, although that
policy can easily be customized.

The `authenticate_from_token` method might also need to be modified
for different applications. The example above assumes Devise is
present, so it uses Devise's `sign_in` method to sign in the user and
set `current_user`. The `store: false` option prevents the user's
identity from being saved in the session, so subsequent API requests
will still require the `secret` and `secret_id`. This code could be
easily modified to directly set `current_user`, or whatever is most
appropriate for an application not using Devise.

#### Communicating Secrets to the User

Each user has to know his/her secret_id and secret in order to log
in. How to best communicate these credentials to users depends on the
needs of your particular application. Some applications might allow
users to view their API credentials from a web page. Others might only
send the credentials via email, or in response to other API calls
(such as those that create new user accounts).

Note, however, that since we're hashing our secrets, the only time we
can show the user a secret is at the time it is first created. There's
no way for a user to come back later and ask for a secret that's been
forgotten. This is better for security, but it needs to be anticipated
by the UI design of our application. Some services handle this by
requiring the API token to be replaced (and any existing token
invalidated) any time the user needs to retrieve it, but our decoupled
design allows you to create multiple valid tokens for each user if you
want. Whatever solution you plan to implement, you can use the console
to verify that it's easy to retrieve the credentials of a
newly-created token:

```
$ rake db:migrate && rails console
> token = AuthenticationToken.create; [token.secret_id, token.secret]
 ...
 => ["42aa20ee181a2201", "hWIW41mF1wvvN_3TC5ObaFXBrdWPdEJBWjnGduuGwmA"]
```

But when the same token is freshly loaded from the database,
its secret is unknown.

```
> token = AuthenticationToken.find(token.id); [token.secret_id, token.secret]
 ...
 => ["42aa20ee181a2201", nil]
```

#### Conclusion

The above code comes with no guarantee of security, and you should use
it (along with any modifications you make to suit your own
application) with caution, especially because it hasn't been vetted by
real-world use. But since it's built around a core of bcrypt, and it
aims for a decoupled, maintainable object-oriented design, it should
be a good starting point for a post-Devise solution for token
authentication. Try it on for size, and let me know what you think.
