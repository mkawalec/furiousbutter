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

Honestly? I am unsure why it would be beneficial to have a client side
only blogging engine. I hope that in the course of developement an
unusual feature will reveal itself (webRTC will probably be of a lot of
help here) and it will make much more sense to have this client in pure
JS.

Think of it as a research project for now.

### Who is it for?

At the current stage, purely for JS and CoffeeScript hackers. But after
it is able to display stuff, it should be much more inclusive.

## TODO

- [ ] Finish documenting the code
- [ ] Drop dependence on jQuery
- [ ] Make the basic interace useful
- [ ] Add a Backbone interface (rendering engine)

### Useful functions

Almost every furiousbutter class inherits the basic helper functions
from helpers. If you write your own extension you will most probably
like to interit from it too.

    class Helpers

It is useful to be able to extend a class. And even more useful to add
instance and class properties properties.

        extend: (obj) ->
            for key, value of obj
                @[key] = value

        @include: (obj) ->
            for key, value of obj
                @::[key] = value

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

        add_params: (route, params) ->
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

The tags are formated as 'value: property1, property2'. Of course any
unneeded whitespace is trimmed.

                    prop = _.first line.split(':')
                    memo[prop] = $.trim line.split(':')[1]
                    if memo[prop].indexOf(',') != -1
                        memo[prop] = _.each memo[prop].split(','), (i) -> $.trim i
                    return memo
            , {})

    class Cache
        @cache = {}
        @dirty = false
        @storage_key = 'FuriousButter'

        constructor: ->
            if window.localStorage?
                setInterval(@persist, 5000)
                if localStorage[Cache.storage_key]?
                    Cache.cache = JSON.parse localStorage[Cache.storage_key]

        get: (key) ->
            if _.has(Cache.cache, key)
                if @timeout(key) then delete Cache.cache[key]
                else return Cache.cache[key].payload
            return undefined

        set: (key, value, timeout=3600) ->
            Cache.cache[key] = {
                expires: (new Date()).getTime() + 1000 * timeout
                payload: value
            }
            Cache.dirty = true
            return key

        timeout: (key) ->
            if (new Date()).getTime() > Cache.cache[key].expires then return true
            return false

        persist: ->
            if not Cache.dirty then return
            window.localStorage[Cache.storage_key] = JSON.stringify Cache.cache

            Cache.dirty = false

    class CachedAjax extends Helpers
        cache: new Cache

        ajax: (params, timeout) =>
            if @cache.get(params.url) then params.success @cache.get(params.url)
            else
                params.success = ((callback) => (data) =>
                    @cache.set(params.url, data, timeout)
                    callback data
                )(params.success)

                $.ajax params

        get: (url, callback=( -> ), timeout) =>
            @ajax {url: url, type: 'GET', success: callback}, timeout

        post: (url, data, callback=( -> ), timeout) =>
            @ajax {url: url, data: data, type: 'POST', success: callback}, timeout

        put: (url, data, callback=( -> ), timeout) =>
            @ajax {url: url, data: data, type: 'PUT', success: callback}, timeout

        delete: (url, callback=( -> ), timeout) =>
            @ajax {url: url, type: 'DELETE', success: callback}, timeout

    class Router extends Helpers
        @routes: {}

        @route: (route, fn) ->
            Router.routes[route] = fn
            return fn

        @goto: (route, params...) ->
            [route, route_params] = @pull_params route
            params = _.foldl(params, (memo, value, key) ->
                memo[key] = value
                return memo
            , route_params)

            window.location.hash = "##{ @add_params route, params }"

        @hashchange: (e) ->
            e.preventDefault()

            [route, params] = @pull_params location.hash.slice(1)
            if _.has(Router.routes, route) then Router.routes[route](params)

    class Theme extends Helpers
        @include new CachedAjax()

        @register: (instance) -> Blog.themes[@name] = instance

        @get_theme: (blog, theme, ctx={}, callback=( -> )) ->
            blog.get "themes/#{ blog.spec.theme }/html/#{ theme }.html", (data) ->
                [header, body] = _.filter data.split('---'), (i) -> i.length > 0
                # If there is no header in the file
                if not body? then [header, body] = [body, header]

                renderer = blog.spec.renderer
                if header? and _.has(header, 'renderer') then renderer = header.renderer
                    
                data = Blog.renderers[renderer] ctx, body
                callback.call blog, data

        render_index: (ctx, callback) ->
            @blog_instance = ctx
            Theme.get_theme @blog_instance, 'index', {}, callback

    class Blog extends CachedAjax
        @cache: new Cache()
        @renderers: {
            native: (context, body) =>
                compiled = Blog.cache.get(body)
                if not compiled? then compiled = _.template body
                return compiled context
        }
        @themes: {}
        posts: []

        parse_data: (callback=( -> ), filename) =>
            @get "posts/#{ filename }", (data) =>
                [header, post] = _.filter data.split('---'), (i) -> i.length > 0
                [lead, body] = post.split /^--$/
                if not body? then [lead, body] = [body, lead]

                header = @parse_header header
                callback {header: header, lead: marked(lead ? ''), \
                    body: marked(body ? ''), filename: filename}

        post_parsed: (post) => Blog.themes[@spec.theme].render_post post, @posts_list

        constructor: (@spec={}) ->
            if not _.has(@spec, 'renderer') then @spec.renderer = 'native'
            Blog.themes[@spec.theme].render_index @, @get_posts

        get_posts: (params={}, callback=@post_parsed) ->
            @get 'posts/index.txt', (data) =>
                @posts_list = _.filter data.split('\n'), (i) -> i? and i.length > 0
                if _.has(params, 'after')
                    end = params.limit ? undefined
                    @posts_list = @posts_list.slice(
                        _.indexOf(@posts_list, decodeURIComponent(params.after)) + 1,
                        end)
                else if _.has(params, 'before')
                    end = _.indexOf(@posts_list, decodeURIComponent(params.before))
                    begin = if params.limit then (end - params.limit) else 0
                    @posts_list = @posts_list.slice(begin, end)

                _.each @posts_list, _.partial(@parse_data, callback)

    window.Blog = Blog
    window.Theme = Theme
    window.CachedAjax = CachedAjax

<!-- vim:set tw=72: -->
