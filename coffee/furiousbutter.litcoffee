FuriousButter
-------------

The small and agile client-side blog framework. The idea here
is to write your posts in markdown and then parse everything on
the client side however you want without the hassle of learning
a large codebase.

There is another advantage in that frontend developers need not worry
about contacting the server efficiently, it is taken care of in the
background.

### Why only render on the client side?

The more I think about it, the more I realize the amazing potential it
could have - think about private blogs self-hosted on Dropbox. No more
ads. No more being dependent on some kind of an external blogging
platform. 

However, the code quality is still pretty rough and it only displays a
text string now so think of it as a research project for now.

There are hardly any benefits of this way of doing things over just
having the blog rendered offline, and there are even slight
disadvantages (though making people upgrade their browsers is more of an
service to humanity). I expect this approach to gain a huge boost with
the advent of WebRTC.

So generally, the conclusion here is: it is awesome and can have some
practical uses by accident.

### Who is it for?

At the current stage, purely for JS and CoffeeScript hackers. But after
it is able to display stuff, it should be much more inclusive.

## TODO for first release

- [x] Finish documenting the code
- [x] Routes use Regular Expressions
- [x] In-route parameters enclosed by '<' and '>'
- [ ] Return promises apart from accepting callbacks
- [ ] Add a plug-ins architecture
- [ ] Tests for every function
- [ ] Make the basic theme display useful stuff
- [ ] window.feed(type='atom') should return a feed of a given type

### Useful functions

Almost every furiousbutter class inherits the basic helper functions
from here. If you write your own extension you will most probably
like to inherit from it too.

    class Helpers

It is useful to be able to extend a class. 

        extend: (obj) ->
            for key, value of obj
                @[key] = value

When routing it is of great help to extract the address and url-decoded
parameters from an URI.

        pull_params: (route) ->

Faced with standards-abiding URIs, the left part of ? will be the
address and the right will contain various parameters.

            addr = route.split('?')[0]
            params = {}

            if route.split('?').length > 1

If there are any parameters, they need to be extracted from the string
containing all of them and then decoded from URI representation

                raw_params = route.split('?')[1].split('&')
                params = _.foldl(raw_params, (memo, param) ->
                    memo[decodeURIComponent(param.split('=')[0])] = \
                        decodeURIComponent(param.split('=')[1])
                    return memo
                , {})
            return [addr, params]

Of course extracting the parameters is just half of the job - we want to
be able to create the parameter-containing addresses.

        add_params: (route, params={}) ->
            _.each params, (value, key) ->

The first parameter needs to be separated from the address by ?, while
the rest are separated by & from each other. Each of the parameters is
URI encoded.

                if '?' not in route then route += '?'
                else route += '&'

                route += "#{ encodeURIComponent key }=#{ encodeURIComponent value.toString() }"
            return route

Quite often a list of tags inside the header-like region of a file will
be needed, so Helpers accommodate for that end.

        parse_header: (header) ->
            return _.foldl(_.filter(header.split('\n'), (i) -> i.length > 0),
                (memo, line) ->

The tags are formated as 'value: property1, property2' and any unneeded
whitespace is trimmed.

                    prop = _.first line.split(':')
                    memo[prop] = $.trim line.split(':')[1]
                    if memo[prop].indexOf(',') != -1
                        memo[prop] = _.each memo[prop].split(','), (i) -> $.trim i
                    return memo
            , {})

A final route regular expression needs generation, with inline
parameters expanded into a matching blocks. Also, the parameter names
are returned, to enable us to easily reference them later.

        expand_params: (route) ->
            matcher = route.replace /<[\w%]+>/g, "(\\w+.{0})"
            params = _.foldl route.match(/<[\w%]+>/g), (memo, param) ->
                memo.push _.first param.match /[\w%]+/
                memo
            , []

            return {matcher: new RegExp(matcher), params: params}
                

### Client side-cache

As we want to limit the server requests to minimum, every data request
is passed through a **Cache** that saves its results for a certain time.
And because the blog only issues GET requests there is no need to deal
with cache invalidation.

    class Cache

There are two cache levels - the cache object available at
**Cache**.cache and the *localStorage* cache. Former is used to provide
fast access and the latter provides data persistence between page
reloads. The downside of the current implementation is that both caches
are kept (more or less) the same, so the size of both has to be equal.

        @cache = {}
        @dirty = false

The *localStorage* key under which the contents of @cache are saved.

        @storage_key = 'FuriousButter'

Remove all the cached information if called.
        
        @clear: ->
            @cache = {}
            localStorage.removeItem Cache.storage_key

        constructor: ->

We want to only use the localStorage if it is available in the browser.
If it is, schedule the change persister method to be executed every set
time and load the last cache state (if it exists).

            if window.localStorage?
                setInterval @persist, 1000
                Cache.cache = JSON.parse (localStorage[Cache.storage_key] ? '{}')

Get an object with a given key, or an *undefined* if it doesn't exist.

        get: (key) ->
            key = if typeof key == 'string' then key else JSON.stringify key

            if _.has(Cache.cache, key)
                if @timeout(key) then delete Cache.cache[key]
                else return Cache.cache[key].payload
            return undefined

Set a value referenced by a key and an optional timeout. Notice that
setting the same key more than once will overwrite the value currently
saved at this key.

        set: (key, value, timeout=3600) ->
            key = if typeof key == 'string' then key else JSON.stringify key

Mark the cache persistable and return the saved cache object.

            Cache.dirty = true
            Cache.cache[key] = {
                expires: (new Date()).getTime() + 1000 * timeout
                payload: value
            }

Check if an element with the provided key has expired or not.

        timeout: (key) ->
            if (new Date()).getTime() > Cache.cache[key].expires then return true
            return false

Serialize the **Cache**.cache object and save in the *localCache* if
there were any modifications to the cache state.

        persist: ->
            if not Cache.dirty then return
            window.localStorage[Cache.storage_key] = JSON.stringify Cache.cache

            Cache.dirty = false

### Cached Ajax methods

As far as the later parts of the app are concerned, the cache is
abstracted out by the following class. The other methods (post, put and
delete) are provided for completeness sake.

    class CachedAjax extends Helpers
        cache: new Cache

The full-blown cached version of jQuery ajax is needed at times and so
it is provided. It gets the data from the **Cache** if it exists there or
saves it in **Cache** before executing the success callback if a network
request is needed.

        ajax: (params, cache_timeout) =>
            new Promise (resolve, reject) =>
                if @cache.get(params.url) 
                    cached = @cache.get params.url
                    params.success? cached
                    resolve cached
                else
                    params.success = ((callback) => (data) =>
                        @cache.set(params.url, data, cache_timeout)

                        callback? data
                        resolve data
                    )(params.success)

                    params.error = ((error) -> ->
                        error?.apply @, arguments
                        reject()
                    )(params.error)

                    $.ajax params

Shorthand versions of the above, should cater to 95% of usage scenarios.

        get: (url, callback=( -> ), timeout) =>
            @ajax {url: url, type: 'GET', success: callback}, timeout

        post: (url, data, callback=( -> ), timeout) =>
            @ajax {url: url, data: data, type: 'POST', success: callback}, timeout

        put: (url, data, callback=( -> ), timeout) =>
            @ajax {url: url, data: data, type: 'PUT', success: callback}, timeout

        delete: (url, callback=( -> ), timeout) =>
            @ajax {url: url, type: 'DELETE', success: callback}, timeout

### URI Routing

A basic router is useful to bind a certain functions to a specified URI.
There is really nothing more that this class does.

    class Router extends Helpers

Currently bound routes can be accessed at **Router**.routes.

        @routes: []

Removes all the existing routes

        @clear: -> Router.routes = []

Create a route for the function and return the provided function.

        route: (route, fn) -> 
            if typeof route == 'object'
                route = route.toString().replace /\\/g, "\\\\"
                if _.first(route) == '/' and _.last(route) == '/'
                    route = route.slice 1, route.length - 1

If a route that is the same already exists, the function will not add
the new route and fail silently. I am unsure if this is a right thing to
do. TODO.

            expanded = @expand_params route
            unless _.some(Router.routes, (route) -> 
                    route.route.toString() == expanded.matcher.toString())
                Router.routes.push {
                    pattern: new RegExp route
                    route: expanded.matcher
                    params: expanded.params
                    callback: fn
                }

Navigates to the given route making sure that the parameters are
correctly parsed. *params* can be any number of parameters that are
either primitive types, objects or arrays. Using arrays and primitive
types should be avoided, though.

        goto: (route, params...) ->

Pull out any parameters that are included in the route at the time of
calling the function.

            [route, route_params] = @pull_params route
            params = _.foldl(params, (parsed_params, param) ->

If the parameter being parsed is neither an *Object* nor an *Array* just set
the parameter key to the value of the parameter. This can cause various
hard to find bugs, so try to avid using such parameters.

                if typeof param != "object"
                    parsed_params[param] = param
                    return parsed_params

If it is an *Object*, set the parsed_params keys and values to those in
the currently processed object. Remember that *Array* is also an
*Object* and if *param* is an *Array* the keys will be the consecutive
array indexes. This **will** create conflicts if more than one array is
provided in *params*.

                return _.extend parsed_params, _.foldl(param, (memo, value, key) ->
                    memo[key] = value
                    return memo
                , {})
            , {})

            window.location.hash = \
                "##{ @add_params route, _.extend(params, route_params) }"

This method is the hashchange event processor and navigates to a route
if **Router** knows about its existence.

        hashchange: (e) ->
            e?.preventDefault()

            [route, params] = @pull_params location.hash.slice(1)

Execute the first function that matches the route. Provide some request
data as context.

            if (matching_route = _.find(Router.routes, (value) ->
                    if route.match value.route then return true else return false))?

Find out which parentheses inside router regular expression contain
inline parameters and get their indexes.

                params_indexes = _.foldl(matching_route.route.toString().match(/\(.*?\)/g), 
                    (memo, value, index) ->
                        if value == '(\\w+.{0})' then memo.push index
                        memo
                    , []
                    )

Add the values of correct parameters to the parameters object.

                _.extend(params, _.foldl params_indexes, (memo, index,
                    param_index) ->
                        memo[matching_route.params[param_index]] = 
                            route.match(matching_route.route)[index+1]
                        memo
                , {}
                )

Call the matching route with some parameters as context.

                matching_route.callback.call {
                    route: route
                    route_pattern: matching_route.pattern
                    params: params 
                    event: e
                }, params


### The themes controller

Actually putting stuff on screen is important, and the **Theme** class
is brave enough to take control of it. It gives the themes the ability
to notify the backend of their existence, as well as some helper
functionality. When writing a theme, inherit from this class.

    class Theme extends CachedAjax

All the registered themes sit in the **Theme**.themes object.
Registering a new theme just adds a new entry with the theme class name
as key.

        @themes = {}
        @register: (instance) -> Theme.themes[@name] = instance

Calls the callback with the parsed template data.

        @get_theme: (blog, theme_part, ctx={}, callback=( -> )) ->
            blog.get "themes/#{ blog.spec.theme }/html/#{ theme_part }.html", (data) ->
                [header, body] = _.filter data.split('---'), (i) -> i.length > 0

If there is no header section in the file being parsed the first element
returned by the *\_.filter* above will be the theme body. We need to
exchange the element order in such a case

                if not body? then [header, body] = [body, header]

Render with the renderer provided in the renderer section of theme
header or, if no rendering method is provided, render with the default
method for the current blog.

                renderer = blog.spec.renderer
                if header? and _.has(header, 'renderer') then renderer = header.renderer

Parse the theme body and call the callback with that data.
                    
                data = Blog.renderers[renderer] ctx, body
                callback.call blog, data

This method is called by the **Blog** when it wants to render a
template. The callback points to the action the blog wants to invoke
after the index is rendered.

        render_index: (ctx, callback) ->
            @blog_instance = ctx
            Theme.get_theme @blog_instance, 'index', {}, callback

### The Blog itself

Now that we have all of the foundations ready, let's create the actual
**Blog**. 

    class Blog extends CachedAjax

All the **Blog** classes share the same **Cache** object, as we want
cache access from class methods.

        @cache: new Cache()

Template compilers (or renderers) that the **Blog** knows about sit
inside the renderers attribute. By default the default *native* renderer
is provided which uses *underscore.js* templates.

        @renderers: {
            native: (context, body) =>
                compiled = Blog.cache.get(body)
                if not compiled? then compiled = _.template body
                return compiled context
        }
        @themes: {}
        posts: []

An abstraction layer is needed for post parsing and is provided by the
following.

        parse_post: (callback=( -> ), filename) =>
            @get "posts/#{ filename }", (data) =>

After getting the file, contents parsing (which is relatively costly)
should only be initiated if there is no cached version of the parsed
post available in the **Blog**.cache.

                if cached = Blog.cache.get(filename) then return callback cached

A header section is obligatory for a post, while a lead is not. If there
is no lead then the body and lead order must be inverted so that each
contain correct data. A post needs at minimum only a header, additional
information is optional.

                [header, post] = _.filter data.split('---'), (i) -> i.length > 0
                [lead, body] = post.split /^--$/
                if not body? then [lead, body] = [body, lead]

After parsing the header a ready to return object containing the parsed
data is created, saved in the cache and passed as a first argument to
the callback.

                header = @parse_header header
                cached = {header: header, lead: marked(lead ? ''), \
                    body: marked(body ? ''), filename: filename}

                Blog.cache.set(filename, cached)
                callback cached

After each post is parsed it is fed to a currently selected theme to
actually be displayed along with a parsed list of all the posts so that
the frontend can properly align the post on a page.

        post_parsed: (post) => Theme.themes[@spec.theme].render_post post, @posts_list

        constructor: (@spec={}) ->

If no default renderer is set through the runtime configuration, the
'native' renderer is chosen as default.

            if not _.has(@spec, 'renderer') then @spec.renderer = 'native'

There is no need to set a default theme if only one theme is available,
but it is useful if more are provided on the page.

            if not @spec.theme? then @spec.theme = _.first _.keys Theme.themes
            Theme.themes[@spec.theme].render_index @, @get_posts

And finally, we need a method to actually get the posts

        get_posts: (params={}, callback=@post_parsed) ->

Because the requests are transparentely cached for us, we can rest
peacefully knowing that the network will be involved at a minimal level.

            @get 'posts/index.txt', (data) =>
                if not params.limit? then params.limit = 10

The posts list will consist of every nonempty line from the index file.

                @posts_list = _.filter data.split('\n'), (i) -> i? and i.length > 0

Apart from just requesting the full unfiltered postlist, it is possible
to process a list of posts after and before a certain post. 

                if _.has(params, 'after')
                    next_location = _.indexOf(@posts_list,
                        decodeURIComponent(params.after)) + 1
                    @posts_list = @posts_list.slice(next_location,
                        next_location + params.limit)
                else if _.has(params, 'before')
                    end = _.indexOf(@posts_list, decodeURIComponent(params.before))
                    begin = end - params.limit
                    @posts_list = @posts_list.slice(begin, end)

We make sure that a right number of posts will be received, which is
needed when neither after nor before parameter were specified. Each post
is then scheduled to be parsed.

                @posts_list = _.first @posts_list, params.limit
                _.each @posts_list, _.partial(@parse_post, callback)

Making some classes available globally.

    window.Blog         = Blog
    window.Theme        = Theme
    window.Router       = Router
    window.Helpers      = Helpers
    window.Cache        = Cache
    window.CachedAjax   = CachedAjax

<!-- vim:set tw=72:setlocal formatoptions-=c: -->
